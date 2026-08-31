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
        for member in settings.family.members:
            sample = member.id
            sex = "1" if member.sex == "M" else "2"
            father = member.father or "0"
            mother = member.mother or "0"
            calls = (
                [alleles[matrix.sample_index[sample]][index] for index in selected_indices]
                if sample in matrix.sample_index
                else ["N/N"] * selected_indices.size
            )
            pedigree_rows.append("\t".join(["1", sample, father, mother, sex, *calls]))
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
        error_lines = errors.read_text(encoding="utf-8").splitlines()[1:]
        rejected = {columns[2] for line in error_lines if len(columns := line.split()) >= 3}
    if rejected:
        _remove_rejected_markers(prefix, {str(value) for value in rejected})
    with (directory / f"merlin{suffix}.o").open("a", encoding="utf-8") as output:
        subprocess.run(
            [executable, *common, f"--{model}", "--prefix", str(prefix)],
            check=True,
            stdout=output,
        )


def _remove_rejected_markers(prefix: Path, rejected: set[str]) -> None:
    """Remove error-marked marker columns consistently from DAT, MAP, and PED files."""
    dat_path = Path(f"{prefix}.dat")
    map_path = Path(f"{prefix}.map")
    ped_path = Path(f"{prefix}.ped")
    dat_lines = dat_path.read_text(encoding="utf-8").splitlines()
    marker_ids = [line.split()[1] for line in dat_lines]
    keep = [marker not in rejected for marker in marker_ids]
    dat_path.write_text(
        "\n".join(line for line, retain in zip(dat_lines, keep, strict=True) if retain) + "\n",
        encoding="utf-8",
    )
    map_lines = map_path.read_text(encoding="utf-8").splitlines()
    map_path.write_text(
        "\n".join(line for line in map_lines if line.split()[1] not in rejected) + "\n",
        encoding="utf-8",
    )
    pedigree_lines = []
    for line in ped_path.read_text(encoding="utf-8").splitlines():
        columns = line.split()
        calls = [call for call, retain in zip(columns[5:], keep, strict=True) if retain]
        pedigree_lines.append("\t".join([*columns[:5], *calls]))
    ped_path.write_text("\n".join(pedigree_lines) + "\n", encoding="utf-8")


def _parse_blocks(
    path: Path, samples: tuple[str, ...], chromosomes: tuple[str, ...] = CHROMOSOMES
) -> dict[str, np.ndarray]:
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
                active = re.sub(r"\([^)]*\)", "", line).split()
                continue
            pairs = re.findall(r"(\S+)\s+[^\w\s,]\s+(\S+)", line)
            if active and len(pairs) == len(active):
                for sample, (first, second) in zip(active, pairs, strict=True):
                    if sample in sample_values:
                        sample_values[sample].append(
                            f"{first}|{second}".replace("?", "NA")
                        )
        length = min((len(value) for value in sample_values.values()), default=0)
        if length:
            parsed[chromosomes[min(block_index, len(chromosomes) - 1)]] = np.column_stack(
                [sample_values[sample][:length] for sample in samples]
            )
    return parsed


def _marker_indices(path: Path) -> dict[str, np.ndarray]:
    """Read retained source-site indices from a Merlin map file."""
    indices: dict[str, list[int]] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        columns = line.split()
        if len(columns) < 2 or (match := re.fullmatch(r"id(\d+)", columns[1])) is None:
            raise ValueError(f"Invalid Merlin map row: {line}")
        chrom = columns[0] if columns[0].startswith("chr") else f"chr{columns[0]}"
        indices.setdefault(chrom, []).append(int(match.group(1)) - 1)
    return {chrom: np.asarray(values, dtype=np.int64) for chrom, values in indices.items()}


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
    flow.update(_parse_blocks(output_directory / "merlinX.flow", matrix.samples, ("chrX",)))
    geno = _parse_blocks(output_directory / "merlin.chr", matrix.samples)
    geno.update(_parse_blocks(output_directory / "merlinX.chr", matrix.samples, ("chrX",)))
    marker_indices = _marker_indices(output_directory / "merlin.map")
    marker_indices.update(_marker_indices(output_directory / "merlinX.map"))
    rows: list[dict[str, object]] = []
    for chrom, flow_matrix in flow.items():
        genotype_values = geno.get(chrom)
        source_indices = marker_indices.get(chrom)
        if (
            genotype_values is None
            or source_indices is None
            or genotype_values.shape != flow_matrix.shape
            or source_indices.size != flow_matrix.shape[0]
        ):
            raise ValueError(f"Merlin output rows do not match retained markers for {chrom}")
        keep = ~np.all(np.char.find(genotype_values.astype(str), "NA") >= 0, axis=1)
        flow_matrix = flow_matrix[keep]
        genotype_values = genotype_values[keep]
        positions = sites.pos[source_indices[keep]]
        for sample_index, sample in enumerate(matrix.samples):
            strands = np.asarray([value.split("|", 1) for value in flow_matrix[:, sample_index]])
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
                            "genotype": str(genotype_strands[marker, strand]),
                            "is_corrected": bool(changed[marker, strand]),
                        }
                    )
    result = pl.DataFrame(rows)
    _write_flow_tables(output_directory, result, matrix.samples)
    return result


def _write_flow_tables(
    output_directory: Path, haplotypes: pl.DataFrame, samples: tuple[str, ...]
) -> None:
    """Write one compatibility flow TSV per real sample."""
    palette = (
        "#A6CEE3",
        "#1F78B4",
        "#B2DF8A",
        "#33A02C",
        "#FB9A99",
        "#E31A1C",
        "#FDBF6F",
        "#FF7F00",
        "#CAB2D6",
        "#6A3D9A",
        "#FFFF99",
        "#B15928",
    )
    letters = sorted(set(haplotypes["letter"].to_list())) if not haplotypes.is_empty() else []
    colors = {letter: palette[index % len(palette)] for index, letter in enumerate(letters)}
    colors["X"] = "white"
    for sample in samples:
        frame = haplotypes.filter(pl.col("sample") == sample)
        first = frame.filter(pl.col("strand") == 1).rename(
            {"letter": "flowA", "is_corrected": "flowA.iscorrected"}
        )
        second = frame.filter(pl.col("strand") == 2).rename(
            {"letter": "flowB", "is_corrected": "flowB.iscorrected"}
        )
        joined = (
            first.join(
                second.select("chrom", "pos", "flowB", "flowB.iscorrected"),
                on=["chrom", "pos"],
                how="inner",
            )
            .with_columns(
                pl.col("flowA").replace_strict(colors).alias("flowA.hexcol"),
                pl.col("flowB").replace_strict(colors).alias("flowB.hexcol"),
            )
            .select(
                pl.col("chrom").alias("chr"),
                "pos",
                "flowA",
                "flowA.hexcol",
                "flowA.iscorrected",
                "flowB",
                "flowB.hexcol",
                "flowB.iscorrected",
            )
        )
        joined.write_csv(output_directory / f"{sample}-flow.txt", separator="\t")
