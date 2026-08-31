"""Vectorized engine behavior tests."""

from __future__ import annotations

import logging
import shutil
import subprocess
from pathlib import Path

import numpy as np
import pytest

from hopla.analysis import _duo_errors, _trio_errors, variant_depth_table
from hopla.filters import apply_filter1, apply_filter2
from hopla.merlin import (
    _mark_haploid_x,
    _marker_indices,
    _parse_blocks,
    correct_short_segments,
    weighted_vote,
)
from hopla.models import FilteredGenotypes, GenotypeMatrix, SiteTable
from hopla.pedigree import add_ghosts, predict_sexes
from hopla.settings import Settings, load_settings, validate_settings
from hopla.vcf import load_vcf, mask_male_x_heterozygotes


def test_vcf_and_filters(family_vcf: Path, settings_file: Path) -> None:
    """Load shared matrices and preserve all chromosomes through both filters."""
    settings = load_settings(settings_file)
    sites, matrix = load_vcf(family_vcf, settings.real_samples)
    assert sites.size == 46
    assert matrix.gt.shape == (3, 46)
    mask_male_x_heterozygotes(sites, matrix, settings)
    assert matrix.gt[matrix.sample_index["FATHER"], -1] == -1
    filtered1 = apply_filter1(sites, matrix, settings)
    filtered2 = apply_filter2(sites, matrix, filtered1, settings)
    assert filtered1.gt.shape[1] == 46
    assert filtered2.gt.shape[1] == 23


def test_mendelian_error_rules() -> None:
    """Match the original trio and duo impossibility rules."""
    child = np.asarray([1, 2, 0, 1, 0], dtype=np.int8)
    first = np.asarray([0, 0, 1, 2, 0], dtype=np.int8)
    second = np.asarray([0, 1, 2, 2, 2], dtype=np.int8)
    assert _trio_errors(child, first, second).tolist() == [2, 2, 2, 2, 2]
    assert _duo_errors(np.asarray([2, 0, 1]), np.asarray([0, 2, 1])).tolist() == [2, 2, 0]


def test_haplotype_corrections() -> None:
    """Correct short segments and locally inconsistent markers."""
    flow = np.asarray(["A", "A", "B", "A", "A"])
    genotype = np.asarray(["A", "A", "B", "A", "A"])
    assert correct_short_segments(flow, genotype, 1).tolist() == ["A"] * 5
    voted = weighted_vote(flow, np.asarray([0, 10, 20, 30, 40], dtype=np.uint32), max_distance=25)
    assert voted.tolist() == ["A"] * 5


def test_male_x_marks_the_second_minx_strand_as_absent() -> None:
    """Represent hemizygous male chromosome X without a duplicate haplotype."""
    flow = np.asarray([["A", "A"], ["B", "B"]])
    genotypes = np.asarray([["A", "A"], ["G", "G"]])
    _mark_haploid_x(flow, genotypes)
    assert flow.tolist() == [["A", "X"], ["B", "X"]]
    assert genotypes.tolist() == [["A", "NA"], ["G", "NA"]]


def test_variant_depth_caps_outliers_on_shared_sample_bins() -> None:
    """Keep every count while one extreme depth no longer stretches all panels."""
    first = np.asarray([10] * 200 + [10_000], dtype=np.uint16)
    second = np.asarray([20] * 201, dtype=np.uint16)
    depths = np.vstack((first, second))
    calls = np.zeros(depths.shape, dtype=np.int8)
    matrix = GenotypeMatrix(
        gt=calls,
        dp=depths,
        ad_ref=np.zeros(depths.shape, dtype=np.uint16),
        ad_alt=np.zeros(depths.shape, dtype=np.uint16),
        samples=("first", "second"),
        sample_index={"first": 0, "second": 1},
    )
    filtered = FilteredGenotypes(
        site_mask=np.ones(depths.shape[1], dtype=np.bool_),
        gt=calls,
        dp=depths.astype(np.float32),
        af=np.zeros(depths.shape, dtype=np.float32),
    )

    table = variant_depth_table(matrix, filtered, filtered)
    level = table.filter(table["filter_level"] == 0)
    first_bins = level.filter(level["sample"] == "first")
    second_bins = level.filter(level["sample"] == "second")
    assert first_bins["bin_start"].to_list() == second_bins["bin_start"].to_list()
    assert first_bins["bin_end"].to_list() == second_bins["bin_end"].to_list()
    assert first_bins["bin_end"].max() == pytest.approx(20)
    assert first_bins["count"].sum() == first.size
    assert second_bins["count"].sum() == second.size
    assert first_bins["count"][-1] == 1


def test_parse_merlin_strand_pairs_and_wrapped_samples(tmp_path: Path) -> None:
    """Preserve both strands when Merlin prints samples in separate column groups."""
    path = tmp_path / "merlin.flow"
    path.write_text(
        "\n".join(
            [
                "FAMILY 1 [Most Likely]",
                "          FATHER (F)                 MOTHER (F)",
                "             A : B                     C : D",
                "             A : B                     C : D",
                "             A : B                     C : D",
                "          U1 (F)                      CHILD (FATHER,U1)",
                "             E : F                       A | C",
                "             E / F                       B \\ D",
                "             E : F                       A + D",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    parsed = _parse_blocks(path, ("CHILD", "FATHER", "MOTHER"))
    assert parsed["chr1"].tolist() == [
        ["A|C", "A|B", "C|D"],
        ["B|D", "A|B", "C|D"],
        ["A|D", "A|B", "C|D"],
    ]
    assert list(_parse_blocks(path, ("CHILD", "FATHER", "MOTHER"), ("chrX",))) == ["chrX"]
    map_path = tmp_path / "merlin.map"
    map_path.write_text("1\tid9\t1.0\nX\tid21\t2.0\n", encoding="utf-8")
    assert _marker_indices(map_path)["chr1"].tolist() == [8]
    assert _marker_indices(map_path)["chrX"].tolist() == [20]


def test_mixed_ploidy_and_absent_format_fields(tmp_path: Path) -> None:
    """Load sites that mix haploid and diploid calls or omit FORMAT fields."""
    path = tmp_path / "mixed.vcf"
    path.write_text(
        "\n".join(
            [
                "##fileformat=VCFv4.2",
                '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">',
                '##FORMAT=<ID=AD,Number=R,Type=Integer,Description="Allele depths">',
                '##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Depth">',
                "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tSON\tMUM\tKID",
                # One chromosome-X site mixing haploid male, diploid female, and missing calls.
                "chrX\t100\t.\tA\tG\t.\tPASS\t.\tGT:AD:DP\t1:0,20:20\t0/1:10,10:20\t.:0,0:0",
                "chrX\t150\t.\tA\tG\t.\tPASS\t.\tGT:AD:DP\t0:20,0:20\t0/0:20,0:20\t0/1:10,10:20",
                # A haploid autosomal call is not a diploid homozygote.
                "chr1\t100\t.\tC\tT\t.\tPASS\t.\tGT:AD:DP\t1:0,20:20\t0/1:10,10:20\t0/1:10,10:20",
                # Sites that omit AD/DP entirely must not abort the run.
                "chr1\t200\t.\tC\tT\t.\tPASS\t.\tGT\t0/1\t0/0\t1/1",
                "chr1\t300\t.\tC\tT\t.\tPASS\t.\tGT:AD:DP\t0/1:.,.:.\t0/0:20,0:20\t1/1:0,20:20",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    sites, matrix = load_vcf(path, ("SON", "MUM", "KID"))
    assert sites.size == 5
    # Haploid chrX alt becomes homozygous alt; haploid ref becomes homozygous ref.
    assert matrix.gt[matrix.sample_index["SON"], 0] == 2
    assert matrix.gt[matrix.sample_index["SON"], 1] == 0
    assert matrix.gt[matrix.sample_index["MUM"], 0] == 1
    assert matrix.gt[matrix.sample_index["KID"], 0] == -1
    # Haploid autosomal calls stay uncalled.
    assert matrix.gt[matrix.sample_index["SON"], 2] == -1
    # Absent and missing FORMAT values normalize to zero depth.
    assert matrix.dp[:, 3].tolist() == [0, 0, 0]
    assert matrix.ad_ref[matrix.sample_index["SON"], 4] == 0
    assert matrix.ad_alt[matrix.sample_index["SON"], 4] == 0


def test_requested_sample_order_is_preserved(tmp_path: Path) -> None:
    """Attribute calls by sample name even when settings reorder the VCF columns."""
    path = tmp_path / "order.vcf"
    path.write_text(
        "\n".join(
            [
                "##fileformat=VCFv4.2",
                '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">',
                '##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Depth">',
                "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tAAA\tBBB\tCCC",
                "chr1\t100\t.\tA\tG\t.\tPASS\t.\tGT:DP\t0/0:11\t0/1:22\t1/1:33",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    _, matrix = load_vcf(path, ("CCC", "AAA"))
    assert matrix.dp[matrix.sample_index["CCC"], 0] == 33
    assert matrix.dp[matrix.sample_index["AAA"], 0] == 11
    assert matrix.gt[matrix.sample_index["CCC"], 0] == 2
    assert matrix.gt[matrix.sample_index["AAA"], 0] == 0


def test_unindexed_vcf_warns_when_threads_exceed_one(
    family_vcf: Path, caplog: pytest.LogCaptureFixture
) -> None:
    """Fall back to a sequential scan and warn when the VCF has no index."""
    samples = ("FATHER", "MOTHER", "CHILD")
    with caplog.at_level(logging.WARNING):
        sequential, sequential_matrix = load_vcf(family_vcf, samples, threads=1)
    assert "single-threaded" not in caplog.text
    caplog.clear()
    with caplog.at_level(logging.WARNING):
        parallel, parallel_matrix = load_vcf(family_vcf, samples, threads=4)
    assert "No tabix/CSI index found" in caplog.text
    assert sequential.pos.tolist() == parallel.pos.tolist()
    assert np.array_equal(sequential_matrix.gt, parallel_matrix.gt)
    assert np.array_equal(sequential_matrix.dp, parallel_matrix.dp)


def _compress_and_index_vcf(plain: Path) -> Path:
    """Bgzip and tabix-index a VCF, skipping when htslib tools are absent."""
    bgzip = shutil.which("bgzip")
    tabix = shutil.which("tabix")
    if bgzip is None or tabix is None:
        pytest.skip("bgzip and tabix are required to index a test VCF")
    compressed = Path(f"{plain}.gz")
    with compressed.open("wb") as handle:
        subprocess.run([bgzip, "-c", str(plain)], check=True, stdout=handle)
    subprocess.run([tabix, "-p", "vcf", str(compressed)], check=True)
    return compressed


def test_indexed_vcf_parallel_matches_sequential(tmp_path: Path) -> None:
    """Read an indexed VCF by contig without changing retained sites or sample order."""
    plain = tmp_path / "sites.vcf"
    plain.write_text(
        "\n".join(
            [
                "##fileformat=VCFv4.2",
                "##contig=<ID=chr1,length=1000>",
                "##contig=<ID=chr2,length=1000>",
                '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">',
                '##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Depth">',
                "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tAAA\tBBB",
                "chr1\t100\t.\tA\tG\t.\tPASS\t.\tGT:DP\t0/0:11\t1/1:22",
                "chr1\t200\t.\tC\tT\t.\tPASS\t.\tGT:DP\t0/1:12\t0/0:21",
                "chr2\t150\t.\tG\tA\t.\tPASS\t.\tGT:DP\t1/1:33\t0/1:44",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    compressed = _compress_and_index_vcf(plain)
    samples = ("BBB", "AAA")
    sequential, sequential_matrix = load_vcf(compressed, samples, threads=1)
    parallel, parallel_matrix = load_vcf(compressed, samples, threads=4)
    assert sequential.chrom.tolist() == parallel.chrom.tolist()
    assert sequential.pos.tolist() == parallel.pos.tolist()
    assert np.array_equal(sequential_matrix.gt, parallel_matrix.gt)
    assert np.array_equal(sequential_matrix.dp, parallel_matrix.dp)


def test_af_rounding_and_y_model_conflict_resolution() -> None:
    """Match three-decimal AF and prefer the Y model when X and Y disagree."""
    sites = SiteTable(
        chrom=np.asarray([1, 23, 24], dtype=np.uint8),
        pos=np.asarray([1, 2, 15_000_000], dtype=np.uint32),
        ref=np.asarray(["A", "A", "A"]),
        alt=np.asarray(["G", "G", "G"]),
    )
    matrix = GenotypeMatrix(
        gt=np.asarray([[1, 1, 1]], dtype=np.int8),
        dp=np.asarray([[20, 20, 20]], dtype=np.uint16),
        ad_ref=np.asarray([[2, 1, 1]], dtype=np.uint16),
        ad_alt=np.asarray([[1, 2, 2]], dtype=np.uint16),
        samples=("sample",),
        sample_index={"sample": 0},
    )
    assert np.allclose(matrix.allele_fraction()[0], [0.333, 0.667, 0.667])
    settings = Settings(family={"members": [{"id": "sample"}]}, run_merlin=False)
    predict_sexes(settings, sites, matrix)
    assert settings.family.member("sample").sex == "M"


def test_unsupported_settings_are_ignored(caplog: pytest.LogCaptureFixture) -> None:
    """Remap the historical pedigree arrays and drop unused keys."""
    with caplog.at_level(logging.WARNING):
        settings = validate_settings(
            {
                "sample_ids": ["A"],
                "genders": ["M"],
                "self_contained": True,
                "bogus": 1,
            }
        )
    assert settings.family.member("A").sex == "M"
    assert settings.family.members[0].id == "A"
    assert "bogus" in caplog.text
    assert "self_contained" in caplog.text


def test_structured_family_wins_over_parallel_arrays(
    caplog: pytest.LogCaptureFixture,
) -> None:
    """Prefer the canonical family when both config representations exist."""
    with caplog.at_level(logging.WARNING):
        settings = validate_settings(
            {
                "family": {"members": [{"id": "CANONICAL"}]},
                "sample_ids": ["LEGACY"],
                "sexes": ["M"],
            }
        )
    assert settings.family.member_ids == ("CANONICAL",)
    assert "sample_ids" in caplog.text
    assert "sexes" in caplog.text


def test_generated_ghost_is_added_to_structured_family() -> None:
    """Add a missing parent without creating parallel pedigree state."""
    settings = validate_settings(
        {
            "family": {
                "members": [
                    {"id": "FATHER", "sex": "M"},
                    {"id": "CHILD", "father": "FATHER", "sex": "F"},
                ]
            },
            "run_merlin": False,
        }
    )
    add_ghosts(settings)
    assert settings.family.member("CHILD").mother == "U1"
    assert settings.family.member("U1").sex == "F"
    assert settings.family.member_ids == ("FATHER", "CHILD", "U1")
