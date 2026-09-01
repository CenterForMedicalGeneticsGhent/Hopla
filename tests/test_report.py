"""Report layout and pedigree drawing tests."""

from __future__ import annotations

import json
import re
import tomllib
from html import unescape
from pathlib import Path

import polars as pl

from hopla.models import Cytoband
from hopla.pedigree import _layout, pedigree_svg
from hopla.report import _ado_adi, _variant_totals, render_report
from hopla.settings import Settings

CYTOBANDS = (
    Cytoband(chrom="chr1", start=1, end=1_000_000, name="p11", stain="gneg"),
    Cytoband(chrom="chr1", start=1_000_001, end=2_000_000, name="p11.1", stain="acen"),
    Cytoband(chrom="chr2", start=1, end=1_500_000, name="p11", stain="gpos50"),
)


def _trio() -> Settings:
    """Build a father, mother, and affected child."""
    return Settings(
        family={
            "members": [
                {"id": "father", "sex": "M"},
                {"id": "mother", "sex": "F"},
                {"id": "child", "father": "father", "mother": "mother", "sex": "M"},
            ]
        },
        affected_ids=["child"],
        nonaffected_ids=["father"],
        carrier_ids=["mother"],
        regions=["chr1:500000-900000"],
        info="Example family",
        run_merlin=False,
        baf_ids=["child"],
    )


def test_pedigree_places_children_below_and_between_their_parents() -> None:
    """Draw generations as rows with the sibship centred under the parent couple."""
    settings = _trio()
    positions, depth = _layout(settings)
    assert depth == {"father": 0, "mother": 0, "child": 1}
    assert positions["child"] == (positions["father"] + positions["mother"]) / 2
    assert positions["father"] != positions["mother"]

    svg = pedigree_svg(settings)
    assert 'viewBox="0 0' in svg
    assert svg.count("<rect") == 2  # father and child are male
    assert svg.count("<circle") == 2  # mother plus her carrier dot
    assert 'fill="#334155"' in svg  # the affected child is filled
    assert "child (A)" in svg
    assert "mother (C)" in svg


def test_pedigree_styles_never_reach_the_plotly_figures() -> None:
    """An inline SVG stylesheet is document-wide, so a bare rule would move every axis label."""
    svg = pedigree_svg(_trio())
    assert 'class="pedigree-svg"' in svg
    style = re.search(r"<style>(.*?)</style>", svg)
    assert style is not None
    selectors = re.findall(r"(?:^|\})([^{}]+)\{", style.group(1))
    assert selectors
    for selector in selectors:
        assert selector.strip().startswith(".pedigree-svg"), selector


def test_pedigree_pulls_a_founder_partner_down_to_their_spouse_row() -> None:
    """Keep couples on one row so their relationship line never spans generations."""
    settings = Settings(
        family={
            "members": [
                {"id": "grandmother", "sex": "F"},
                {"id": "grandfather", "sex": "M"},
                {
                    "id": "mother",
                    "father": "grandfather",
                    "mother": "grandmother",
                    "sex": "F",
                },
                {"id": "father", "sex": "M"},
                {"id": "child", "father": "father", "mother": "mother", "sex": "F"},
            ]
        },
        run_merlin=False,
    )
    positions, depth = _layout(settings)
    assert depth["grandmother"] == depth["grandfather"] == 0
    # The father has no parents but marries into the second generation.
    assert depth["mother"] == depth["father"] == 1
    assert depth["child"] == 2
    assert positions["child"] == (positions["mother"] + positions["father"]) / 2


def test_large_family_statistics_use_compact_tables() -> None:
    """Use rows and columns instead of repeated headings that grow the report."""
    children = [f"child-{index}" for index in range(1, 9)]
    samples = ("father", "mother", *children)
    settings = Settings(
        family={
            "members": [
                {"id": "father", "sex": "M"},
                {"id": "mother", "sex": "F"},
                *[
                    {
                        "id": child,
                        "father": "father",
                        "mother": "mother",
                        "sex": "F",
                    }
                    for child in children
                ],
            ]
        },
        regions=["chr1:500000-900000"],
        run_merlin=False,
    )
    variant_stats = pl.DataFrame(
        {
            "filter_level": [0] * len(samples),
            "sample": list(samples),
            "region": ["genome"] * len(samples),
            "metric": ["variants"] * len(samples),
            "value": [float(index) for index in range(len(samples))],
        }
    )
    ado_adi = pl.DataFrame(
        {
            "filter_level": [0] * (len(children) * 2),
            "sample": [child for child in children for _ in range(2)],
            "metric": ["ADO", "ADI"] * len(children),
            "value": [1.25, 2.5] * len(children),
        }
    )

    totals_html = _variant_totals({"variant_stats": variant_stats}, settings, samples, 0)
    ado_html = _ado_adi({"ado_adi": ado_adi}, samples, 0)

    assert '<div class="table-scroll"><table class="matrix">' in totals_html
    assert totals_html.count("<tr>") == 5  # header, overall, region, and two flanks
    assert ">father</th>" in totals_html
    assert '<div class="table-scroll"><table class="matrix">' in ado_html
    assert ado_html.count("<tr>") == len(samples) + 1
    assert "<h5>" not in ado_html
    assert '<td colspan="2">no two parents provided</td>' in ado_html


def test_report_restores_every_original_section() -> None:
    """Emit the documented section order, one figure per panel, and an offline Plotly bundle."""
    settings = _trio()
    samples = ("father", "mother", "child")
    tables = {
        "variant_stats": pl.DataFrame(
            {
                "filter_level": [0, 0],
                "sample": ["child", "child"],
                "region": ["genome", "chr1:500000-900000"],
                "metric": ["variants", "variants"],
                "value": [10.0, 4.0],
            }
        ),
        "genotype_pairs": pl.DataFrame(
            {
                "filter_level": [0],
                "sample_a": ["child"],
                "sample_b": ["child"],
                "genotype_a": ["0/1"],
                "genotype_b": ["0/1"],
                "count": [7],
            }
        ),
        "baf": pl.DataFrame(
            {
                "chrom": ["chr1"],
                "pos": [600_000],
                "sample": ["child"],
                "af": [0.5],
                "filter_level": [1],
            }
        ),
        "copy_number": pl.DataFrame(
            {
                "chrom": ["chr1"],
                "start": [1],
                "end": [1_000_000],
                "sample": ["child"],
                "mean_depth": [30.0],
                "weight": [5],
                "log2_ratio": [0.1],
                "mask": [True],
            }
        ),
    }
    output = Path(__file__).parent / "report.html"
    try:
        render_report(output, settings, tables, samples, CYTOBANDS)
        html = output.read_text(encoding="utf-8")
    finally:
        output.unlink(missing_ok=True)

    titles = [match for match in re.findall(r"<h[234][^>]*>(.*?)</h[234]>", html)]
    assert titles.index("Family/disease information") < titles.index("Family tree")
    assert html.index('class="toc"') < html.index("Family/disease information")
    assert 'href="#family-disease-information"' in html
    assert 'id="family-disease-information"' in html
    assert html.count('href="#variant-statistics') == 3
    assert "Mendelian errors" not in html.split("</nav>", 1)[0]
    for expected in (
        "Filter 0: single nucleotide variants",
        "Vcf-based copy number (bam-based verification recommended)",
        "B-allele frequency (BAF), region(s) of interest",
        "B-allele frequency (BAF), genome-wide",
        "Total number of variants",
        "Number of variants table",
        "Variant depth",
        "Number of variants profile",
    ):
        assert expected in titles, expected

    kinds = [
        json.loads(unescape(spec))["kind"] for spec in re.findall(r"data-spec='([^']*)'", html)
    ]
    assert kinds.count("depth") == len(samples) * 3
    assert kinds.count("density") == 3
    assert kinds.count("cn") == len(samples)
    assert kinds.count("rbaf") == len(samples)
    assert kinds.count("gbaf") == 2  # one panel per chromosome that has cytobands
    assert "Plotly" in html
    assert "application/gzip+json" in html


def test_report_inlines_packaged_assets(tmp_path: Path) -> None:
    """Inline sibling CSS, JS, and the vendored plotly.js basic file."""
    package = Path(__file__).resolve().parents[1]
    css = (package / "src/hopla/report.css").read_text(encoding="utf-8")
    js = (package / "src/hopla/report.js").read_text(encoding="utf-8")
    with (package / "src/hopla/plotly-basic.min.js").open(encoding="utf-8") as handle:
        plotly_head = handle.read(80)
    force_include = tomllib.loads((package / "pyproject.toml").read_text(encoding="utf-8"))[
        "tool"
    ]["hatch"]["build"]["targets"]["wheel"]["force-include"]
    assert force_include["src/hopla/report.css"] == "hopla/report.css"
    assert force_include["src/hopla/report.js"] == "hopla/report.js"
    assert force_include["src/hopla/plotly-basic.min.js"] == "hopla/plotly-basic.min.js"

    output = tmp_path / "family-output.html"
    render_report(output, _trio(), {}, ("father",), CYTOBANDS)
    html = output.read_text(encoding="utf-8")
    assert "table.matrix th.block0" in css
    assert "table.matrix th.block0" in html
    assert "BUILD.depth" in js
    assert "BUILD.depth" in html
    assert plotly_head in html
