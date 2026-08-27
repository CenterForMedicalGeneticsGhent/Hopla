"""Shared synthetic family fixtures."""

from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture
def family_vcf(tmp_path: Path) -> Path:
    """Create a complete tiny trio VCF spanning all analyzed chromosomes."""
    path = tmp_path / "family.vcf"
    header = [
        "##fileformat=VCFv4.2",
        '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">',
        '##FORMAT=<ID=AD,Number=R,Type=Integer,Description="Allele depths">',
        '##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Depth">',
        "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tFATHER\tMOTHER\tCHILD",
    ]
    rows = []
    for chrom in [str(index) for index in range(1, 23)] + ["X"]:
        first_calls = (
            "0/0:20,0:20\t0/1:10,10:20\t0/1:10,10:20"
            if chrom == "X"
            else "0/0:20,0:20\t1/1:0,20:20\t0/1:10,10:20"
        )
        rows.extend(
            [
                f"{chrom}\t100\t.\tA\tG\t.\tPASS\t.\tGT:AD:DP\t{first_calls}",
                f"{chrom}\t200\t.\tC\tT\t.\tPASS\t.\tGT:AD:DP\t0/1:10,10:20\t0/0:20,0:20\t0/1:10,10:20",
            ]
        )
    path.write_text("\n".join(header + rows) + "\n", encoding="utf-8")
    return path


@pytest.fixture
def settings_file(tmp_path: Path) -> Path:
    """Create schema-compatible trio settings with Merlin disabled."""
    path = tmp_path / "settings.yaml"
    path.write_text(
        """
sample_ids: [FATHER, MOTHER, CHILD]
father_ids: [null, null, FATHER]
mother_ids: [null, null, MOTHER]
genders: [M, F, F]
run_merlin: false
keep_informative_ids: [FATHER, MOTHER]
baf_ids: [CHILD]
self_contained: true
""".lstrip(),
        encoding="utf-8",
    )
    return path
