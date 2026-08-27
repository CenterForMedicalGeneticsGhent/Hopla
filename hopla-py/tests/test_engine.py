"""Vectorized engine behavior tests."""

from __future__ import annotations

from pathlib import Path

import numpy as np

from hopla.analysis import _duo_errors, _trio_errors
from hopla.filters import apply_filter1, apply_filter2
from hopla.merlin import correct_short_segments, weighted_vote
from hopla.models import GenotypeMatrix, SiteTable
from hopla.pedigree import predict_genders
from hopla.settings import Settings, load_settings
from hopla.vcf import load_vcf, mask_male_x_heterozygotes


def test_vcf_and_filters(family_vcf: Path, settings_file: Path) -> None:
    """Load shared matrices and preserve all chromosomes through both filters."""
    settings = load_settings(settings_file)
    sites, matrix = load_vcf(family_vcf, settings.real_samples)
    assert sites.size == 46
    assert matrix.gt.shape == (3, 46)
    mask_male_x_heterozygotes(sites, matrix, settings.sample_ids, settings.genders)
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
    settings = Settings(sample_ids=["sample"], genders=[None], run_merlin=False)
    assert predict_genders(settings, sites, matrix) == ["M"]
