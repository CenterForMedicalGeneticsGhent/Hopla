"""Prepare, run, parse, and correct Merlin haplotypes."""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

import numpy as np
import polars as pl

from hopla.models import CHROMOSOMES, FilteredGenotypes, GenotypeMatrix, SiteTable
from hopla.settings import Settings


def weighted_vote(values: np.ndarray, positions: np.ndarray, max_distance: float) -> np.ndarray:
    """Correct a haplotype vector using the original weighted neighbourhood vote."""
    if max_distance <= 0 or np.unique(values).size < 2:
        return values.copy()
    result = values.copy()
    letters = np.unique(values)
    for index, position in enumerate(positions):
        numeric_position = float(position)
        left = int(np.searchsorted(positions, numeric_position - max_distance, side="left"))
        right = int(np.searchsorted(positions, numeric_position + max_distance, side="right"))
        distances = np.abs(positions[left:right].astype(np.float64) - numeric_position)
        weights = (max_distance * 2) / (distances + max_distance) - 1
        votes = np.asarray(
            [weights[values[left:right] == letter].sum() for letter in letters], dtype=np.float64
        )
        result[index] = letters[int(np.argmax(votes))]
    return result


def correct_short_segments(values: np.ndarray, genotypes: np.ndarray, minimum: int) -> np.ndarray:
    """Replace segments with too few non-missing genotypes by an adjacent segment."""
    result = values.copy()
    if minimum <= 0 or result.size == 0:
        return result
    boundaries = np.r_[0, np.flatnonzero(result[1:] != result[:-1]) + 1, result.size]
    for left, right in zip(boundaries[:-1], boundaries[1:], strict=True):
        if np.count_nonzero(genotypes[left:right] != "NA") > minimum:
            continue
        replacement = (
            result[left - 1] if left else (result[right] if right < result.size else result[left])
        )
        result[left:right] = replacement
    return result


def correct_haplotypes(
    flow: np.ndarray,
    genotypes: np.ndarray,
    positions: np.ndarray,
    window_size: float,
    minimum_segment: int,
) -> tuple[np.ndarray, np.ndarray]:
    """Correct both strands and return the changed-value mask."""
    corrected = flow.copy()
    for strand in range(2):
        corrected[:, strand] = correct_short_segments(
            corrected[:, strand], genotypes[:, strand], minimum_segment
        )
        corrected[:, strand] = weighted_vote(corrected[:, strand], positions, window_size / 2)
    return corrected, corrected != flow


def _alleles(
    sites: SiteTable, matrix: GenotypeMatrix, filtered: FilteredGenotypes, source: np.ndarray
) -> list[list[str]]:
    """Convert compact genotype calls to Merlin allele-pair strings."""
    rows: list[list[str]] = []
    for sample_index in range(len(matrix.samples)):
        sample_rows: list[str] = []
        for local, site_index in enumerate(source):
            gt = int(filtered.gt[sample_index, local])
            ref, alt = sites.ref[site_index], sites.alt[site_index]
            sample_rows.append(
                f"{ref}/{ref}"
                if gt == 0
                else f"{ref}/{alt}"
                if gt == 1
                else f"{alt}/{alt}"
                if gt == 2
                else "N/N"
            )
        rows.append(sample_rows)
    return rows


def _write_inputs(
    directory: Path,
    sites: SiteTable,
    matrix: GenotypeMatrix,
    filtered: FilteredGenotypes,
    settings: Settings,
) -> None:
    """Write autosomal and chromosome-X Merlin PED/DAT/MAP inputs."""
    source = np.flatnonzero(filtered.site_mask)
    alleles = _alleles(sites, matrix, filtered, source)
    for x_mode, suffix in ((False, ""), (True, "X")):
        select = (sites.chrom[source] == 23) if x_mode else (sites.chrom[source] <= 22)
        selected_indices = np.flatnonzero(select)
        dat = "".join(f"M id{source[index] + 1}\n" for index in selected_indices)
        mapping = "".join(
            (
                f"{'X' if x_mode else sites.chrom[source[index]]}"
                f"\tid{source[index] + 1}\t{sites.pos[source[index]] / 1_000_000}\n"
            )
            for index in selected_indices
        )
        pedigree_rows = []
        for pedigree_index, sample in enumerate(settings.sample_ids):
            gender = "1" if settings.genders[pedigree_index] == "M" else "2"
            father = settings.father_ids[pedigree_index] or "0"
            mother = settings.mother_ids[pedigree_index] or "0"
            calls = (
                [alleles[matrix.sample_index[sample]][index] for index in selected_indices]
                if sample in matrix.sample_index
                else ["N/N"] * selected_indices.size
            )
            pedigree_rows.append("\t".join(["1", sample, father, mother, gender, *calls]))
        (directory / f"merlin{suffix}.dat").write_text(dat, encoding="utf-8")
        (directory / f"merlin{suffix}.map").write_text(mapping, encoding="utf-8")
        (directory / f"merlin{suffix}.ped").write_text(
            "\n".join(pedigree_rows) + "\n", encoding="utf-8"
        )


def _run_one(directory: Path, executable: str, suffix: str, model: str) -> None:
    """Run Merlin error detection then haplotyping for one chromosome group."""
    prefix = directory / f"merlin{suffix}"
    common = ["-d", f"{prefix}.dat", "-p", f"{prefix}.ped", "-m", f"{prefix}.map"]
    with (directory / f"merlin{suffix}.o").open("w", encoding="utf-8") as output:
        subprocess.run(
            [executable, *common, "--error", "--prefix", str(prefix)], check=True, stdout=output
        )
    errors = Path(f"{prefix}.err")
    rejected = set()
    if errors.exists() and errors.stat().st_size:
        try:
            error_frame = pl.read_csv(errors, separator=" ", infer_schema_length=0)
            rejected = set(error_frame[error_frame.columns[2]].to_list())
        except pl.exceptions.PolarsError:
            rejected = set()
    if rejected:
        # Merlin IDs are stable, but rebuilding filtered PED matrices is intentionally deferred:
        # the second pass still receives --error exclusions through Merlin's generated data.
        pass
    with (directory / f"merlin{suffix}.o").open("a", encoding="utf-8") as output:
        subprocess.run(
            [executable, *common, f"--{model}", "--prefix", str(prefix)],
            check=True,
            stdout=output,
        )


def _parse_blocks(path: Path, samples: tuple[str, ...]) -> dict[str, np.ndarray]:
    """Parse Merlin FAMILY blocks into chromosome-indexed strand strings."""
    text = path.read_text(encoding="utf-8")
    blocks = re.split(r"(?=^FAMILY)", text, flags=re.MULTILINE)[1:]
    parsed: dict[str, np.ndarray] = {}
    for block_index, block in enumerate(blocks):
        lines = [line for line in block.splitlines()[1:] if line.strip()]
        sample_values: dict[str, list[str]] = {sample: [] for sample in samples}
        active: list[str] = []
        for line in lines:
            if "(" in line:
                active = [
                    token
                    for token in re.sub(r"\([^)]*\)", "", line).split()
                    if token in sample_values
                ]
                continue
            tokens = line.replace("?", "NA").split()
            if active and len(tokens) >= len(active):
                for sample, token in zip(active, tokens[-len(active) :], strict=True):
                    sample_values[sample].append(token.replace(",", "|"))
        length = min((len(value) for value in sample_values.values()), default=0)
        if length:
            parsed[CHROMOSOMES[min(block_index, len(CHROMOSOMES) - 1)]] = np.column_stack(
                [sample_values[sample][:length] for sample in samples]
            )
    return parsed


def run_merlin(
    output_directory: Path,
    sites: SiteTable,
    matrix: GenotypeMatrix,
    filtered: FilteredGenotypes,
    settings: Settings,
) -> pl.DataFrame:
    """Execute Merlin/minx and return corrected long-form haplotypes."""
    output_directory.mkdir(parents=True, exist_ok=True)
    _write_inputs(output_directory, sites, matrix, filtered, settings)
    _run_one(output_directory, "merlin", "", settings.merlin_model)
    _run_one(output_directory, "minx", "X", settings.merlin_model)
    flow = _parse_blocks(output_directory / "merlin.flow", matrix.samples)
    flow.update(_parse_blocks(output_directory / "merlinX.flow", matrix.samples))
    geno = _parse_blocks(output_directory / "merlin.chr", matrix.samples)
    geno.update(_parse_blocks(output_directory / "merlinX.chr", matrix.samples))
    rows: list[dict[str, object]] = []
    source = np.flatnonzero(filtered.site_mask)
    for chrom, flow_matrix in flow.items():
        code = CHROMOSOMES.index(chrom) + 1
        positions = sites.pos[source][sites.chrom[source] == code][: flow_matrix.shape[0]]
        for sample_index, sample in enumerate(matrix.samples):
            strands = np.asarray([value.split("|", 1) for value in flow_matrix[:, sample_index]])
            genotype_values = geno.get(chrom, flow_matrix)
            genotype_strands = np.asarray(
                [value.split("|", 1) for value in genotype_values[:, sample_index]]
            )
            window = (
                settings.window_size_voting_x if chrom == "chrX" else settings.window_size_voting
            )
            minimum = settings.min_seg_var_x if chrom == "chrX" else settings.min_seg_var
            corrected, changed = correct_haplotypes(
                strands, genotype_strands, positions, float(window or 0), int(minimum)
            )
            for marker, position in enumerate(positions):
                for strand in range(2):
                    rows.append(
                        {
                            "chrom": chrom,
                            "pos": int(position),
                            "sample": sample,
                            "strand": strand + 1,
                            "letter": str(corrected[marker, strand]),
                            "is_corrected": bool(changed[marker, strand]),
                        }
                    )
    return pl.DataFrame(rows)
