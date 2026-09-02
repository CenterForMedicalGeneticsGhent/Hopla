"""Render the self-contained Plotly HTML report."""

from __future__ import annotations

import base64
import gzip
import json
import re
from html import escape
from pathlib import Path
from typing import Any

import polars as pl

from hopla.cytobands import chromosome_sizes
from hopla.models import CHROMOSOMES, PAIRED_PALETTE, Cytoband
from hopla.pedigree import pedigree_svg, sample_label
from hopla.settings import Settings, parse_region

PALETTE = PAIRED_PALETTE
REPORT_FONT = 'system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif'
GENOTYPES = ("0/0", "0/1", "1/1")
FILTER_TITLES = (
    "Filter 0: single nucleotide variants",
    "Filter 1: filter 0, dp_hard_limit, af_hard_limit and dp_soft_limit",
    "Filter 2: filter 0, filter 1, keep_informative_ids and --keep_hetero_ids",
)


class _Outline:
    """Collect unique heading anchors for a report table of contents."""

    def __init__(self) -> None:
        self.entries: list[tuple[int, str, str]] = []
        self._used: dict[str, int] = {}

    def heading(self, level: int, text: str) -> str:
        """Emit one heading and record it when it belongs in the contents."""
        slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-") or f"section-{level}"
        count = self._used.get(slug, 0) + 1
        self._used[slug] = count
        if count > 1:
            slug = f"{slug}-{count}"
        if level in (2, 3):
            self.entries.append((level, text, slug))
        return f'<h{level} id="{escape(slug)}">{escape(text)}</h{level}>'

    def toc(self) -> str:
        """Render nested contents links for recorded h2 and h3 headings."""
        if not self.entries:
            return ""
        items = []
        for level, text, slug in self.entries:
            indent = ' class="toc-h3"' if level == 3 else ""
            items.append(f'<li{indent}><a href="#{escape(slug)}">{escape(text)}</a></li>')
        return (
            '<nav class="toc" aria-label="Contents"><p class="toc-title">Contents</p>'
            "<ul>" + "".join(items) + "</ul></nav>"
        )


def _json_value(value: Any) -> Any:
    """Normalize Polars scalar values for standards-compliant JSON."""
    if isinstance(value, float) and (value != value or value in (float("inf"), float("-inf"))):
        return None
    return value


def _table_payload(frame: pl.DataFrame) -> dict[str, object]:
    """Encode a DataFrame column-wise so the browser can slice it cheaply."""
    return {
        "columns": frame.columns,
        "data": {
            name: [_json_value(value) for value in frame[name].to_list()] for name in frame.columns
        },
        "rows": frame.height,
    }


def _inline(name: str, tag: str) -> str:
    """Read a sibling report asset and escape it for a style or script element."""
    path = Path(__file__).with_name(name)
    if not path.is_file():
        raise FileNotFoundError(f"Could not locate report asset {name} at {path}")
    return path.read_text(encoding="utf-8").replace(f"</{tag}", f"<\\/{tag}")


def _letter_colors(tables: dict[str, pl.DataFrame]) -> tuple[dict[str, str], str]:
    """Map haplotype letters onto the palette and pick the marking colour."""
    haplotypes = tables.get("haplotypes")
    letters = (
        sorted({letter for letter in haplotypes["letter"].to_list() if letter != "X"})
        if haplotypes is not None and not haplotypes.is_empty()
        else ["A", "B", "C", "D"]
    )
    colors = {letter: PALETTE[index % len(PALETTE)] for index, letter in enumerate(letters)}
    colors["X"] = "#ffffff"
    return colors, PALETTE[len(letters) % len(PALETTE)]


def _cytoband_payload(cytobands: tuple[Cytoband, ...]) -> dict[str, dict[str, list[object]]]:
    """Group cytobands per chromosome as parallel arrays."""
    grouped: dict[str, dict[str, list[object]]] = {}
    for band in cytobands:
        entry = grouped.setdefault(band.chrom, {"start": [], "end": [], "name": [], "stain": []})
        entry["start"].append(band.start)
        entry["end"].append(band.end)
        entry["name"].append(band.name)
        entry["stain"].append(band.stain)
    return grouped


def _regions(settings: Settings) -> list[dict[str, object]]:
    """Parse configured regions into chromosome and coordinate fields."""
    parsed: list[dict[str, object]] = []
    for region in settings.regions:
        chrom, start, end = parse_region(region)
        parsed.append({"label": region, "chrom": chrom, "start": start, "end": end})
    return parsed


def _meta(
    settings: Settings,
    tables: dict[str, pl.DataFrame],
    samples: tuple[str, ...],
    cytobands: tuple[Cytoband, ...],
) -> dict[str, object]:
    """Collect every constant the browser needs to draw the figures."""
    letter_colors, mark_color = _letter_colors(tables)
    sizes = chromosome_sizes(cytobands)
    parents = {
        sample: {
            "father": settings.family.member(sample).father,
            "mother": settings.family.member(sample).mother,
        }
        for sample in samples
    }
    return {
        "samples": list(samples),
        "labels": {sample: sample_label(settings, sample) for sample in samples},
        "parents": parents,
        "chromosomes": [chrom for chrom in CHROMOSOMES if chrom in sizes],
        "sizes": sizes,
        "cytobands": _cytoband_payload(cytobands),
        "regions": _regions(settings),
        "flank": settings.regions_flanking_size,
        "window": settings.window_size,
        "dot": settings.dot_factor,
        "palette": list(PALETTE),
        "letterColors": letter_colors,
        "markColor": mark_color,
        "font": REPORT_FONT,
        "limitBaf": settings.limit_baf_to_p and settings.value_of_p or 0,
        "limitPm": settings.limit_pm_to_p and settings.value_of_p or 0,
        "keepChromosomesOnly": settings.keep_chromosomes_only,
        "keepRegionsOnly": settings.keep_regions_only,
    }


def _figure(spec: dict[str, object], height: int) -> str:
    """Emit one lazily rendered figure placeholder."""
    encoded = escape(json.dumps(spec, separators=(",", ":")), quote=True)
    return f"<div class=\"fig\" style=\"height:{height}px\" data-spec='{encoded}'></div>"


def _grid(figures: list[str], columns: int) -> str:
    """Wrap figure placeholders in a fixed-column grid."""
    return f'<div class="grid" style="--cols:{columns}">' + "".join(figures) + "</div>"


def _count(frame: pl.DataFrame, level: int, sample: str, region: str) -> float:
    """Look up one variant-statistics value."""
    matched = frame.filter(
        (pl.col("filter_level") == level)
        & (pl.col("sample") == sample)
        & (pl.col("region") == region)
    )
    return float(matched["value"][0]) if not matched.is_empty() else 0.0


def _variant_totals(
    tables: dict[str, pl.DataFrame], settings: Settings, samples: tuple[str, ...], level: int
) -> str:
    """Render genome-wide and per-region variant counts as a compact table."""
    frame = tables.get("variant_stats")
    if frame is None or frame.is_empty():
        return ""

    header = "".join(
        f'<th class="block{index % 2}">{escape(sample)}</th>'
        for index, sample in enumerate(samples)
    )
    scopes = [("overall", "genome")]
    for region in settings.regions:
        scopes.extend(
            (
                (f"in {region}", region),
                (f"in {region} (left flank)", f"{region} (left flank)"),
                (f"in {region} (right flank)", f"{region} (right flank)"),
            )
        )
    rows = [f"<tr><th>Scope</th>{header}</tr>"]
    for label, region in scopes:
        cells = "".join(
            f"<td>{_count(frame, level, sample, region):,.0f}</td>" for sample in samples
        )
        rows.append(f'<tr><th class="row-label">{escape(label)}</th>{cells}</tr>')
    return '<div class="table-scroll"><table class="matrix">' + "".join(rows) + "</table></div>"


def _genotype_table(tables: dict[str, pl.DataFrame], samples: tuple[str, ...], level: int) -> str:
    """Render the pairwise genotype-count grid of the original report."""
    frame = tables.get("genotype_pairs")
    if frame is None or frame.is_empty():
        return ""
    counts = {
        (
            str(row["sample_a"]),
            str(row["sample_b"]),
            str(row["genotype_a"]),
            str(row["genotype_b"]),
        ): int(row["count"])
        for row in frame.filter(pl.col("filter_level") == level).iter_rows(named=True)
    }
    header = "".join(
        f'<th class="block{index % 2}" colspan="3">({index + 1}) {escape(samples[index])}</th>'
        for index in range(len(samples))
    )
    rows = [f'<tr><th></th><th></th>{header}</tr>']
    genotype_header = "".join(
        f'<th class="block{index % 2}">{genotype}</th>'
        for index in range(len(samples))
        for genotype in GENOTYPES
    )
    rows.append(f"<tr><th></th><th></th>{genotype_header}</tr>")
    for row_index, row_sample in enumerate(samples):
        for genotype_index, row_genotype in enumerate(GENOTYPES):
            cells = []
            for column_index, column_sample in enumerate(samples):
                for column_genotype in GENOTYPES:
                    if column_index > row_index or (
                        column_index == row_index and column_genotype != row_genotype
                    ):
                        cells.append('<td class="empty"></td>')
                        continue
                    value = counts.get(
                        (row_sample, column_sample, row_genotype, column_genotype), 0
                    )
                    cells.append(f"<td>{value:,.0f}</td>")
            label = (
                f'<th class="block{row_index % 2}" rowspan="3">({row_index + 1}) '
                f"{escape(row_sample)}</th>"
                if genotype_index == 0
                else ""
            )
            rows.append(
                f'<tr>{label}<th class="block{row_index % 2}">{row_genotype}</th>'
                + "".join(cells)
                + "</tr>"
            )
    return '<table class="matrix">' + "".join(rows) + "</table>"


def _ado_adi(tables: dict[str, pl.DataFrame], samples: tuple[str, ...], level: int) -> str:
    """Render allelic drop-out and drop-in percentages per child as a table."""
    frame = tables.get("ado_adi")
    rows = ["<tr><th>Sample</th><th>ADO</th><th>ADI</th></tr>"]
    for index, sample in enumerate(samples):
        matched = (
            frame.filter((pl.col("filter_level") == level) & (pl.col("sample") == sample))
            if frame is not None and not frame.is_empty()
            else None
        )
        if matched is None or matched.is_empty():
            rows.append(
                f'<tr><th class="block{index % 2} row-label">{escape(sample)}</th>'
                '<td colspan="2">no two parents provided</td></tr>'
            )
            continue
        values = {str(row["metric"]): row["value"] for row in matched.iter_rows(named=True)}
        cells = []
        for metric in ("ADO", "ADI"):
            value = values.get(metric)
            text = "NA" if value is None or value != value else f"{value}%"
            cells.append(f"<td>{text}</td>")
        rows.append(
            f'<tr><th class="block{index % 2} row-label">{escape(sample)}</th>'
            + "".join(cells)
            + "</tr>"
        )
    return '<div class="table-scroll"><table class="matrix">' + "".join(rows) + "</table></div>"


def _concordance_table(tables: dict[str, pl.DataFrame], samples: tuple[str, ...]) -> str:
    """Render pairwise strand concordance as a matrix in pedigree sample order."""
    frame = tables.get("haplotype_concordance")
    if frame is None or frame.is_empty():
        return ""
    values: dict[tuple[str, int, str, int], float | None] = {}
    for row in frame.iter_rows(named=True):
        left = (str(row["sample_a"]), int(row["strand_a"]))
        right = (str(row["sample_b"]), int(row["strand_b"]))
        values[(*left, *right)] = row["concordance_percent"]
        values[(*right, *left)] = row["concordance_percent"]
    present = {(sample, strand) for sample, strand, _, _ in values}
    strands = [
        (sample, strand)
        for sample in samples
        for strand in (1, 2)
        if (sample, strand) in present
    ]
    header = "".join(
        f'<th class="block{index % 2}">{escape(sample)}-{strand}</th>'
        for index, (sample, strand) in enumerate(strands)
    )
    rows = [f"<tr><th></th>{header}</tr>"]
    for row_index, (row_sample, row_strand) in enumerate(strands):
        cells = []
        for column_index, (column_sample, column_strand) in enumerate(strands):
            if column_index > row_index:
                cells.append('<td class="empty"></td>')
                continue
            if column_index == row_index:
                cells.append("<td>100%</td>")
                continue
            value = values.get((row_sample, row_strand, column_sample, column_strand))
            cells.append("<td>-</td>" if value is None else f"<td>{value}%</td>")
        rows.append(
            f'<tr><th class="block{row_index % 2}">{escape(row_sample)}-{row_strand}</th>'
            + "".join(cells)
            + "</tr>"
        )
    return '<table class="matrix">' + "".join(rows) + "</table>"


def _statistics_block(
    tables: dict[str, pl.DataFrame],
    settings: Settings,
    samples: tuple[str, ...],
    level: int,
    outline: _Outline,
) -> str:
    """Render the shared variant-statistics block of one filter stage."""
    parts = [
        outline.heading(3, "Variant statistics"),
        "<h4>Total number of variants</h4>",
        _variant_totals(tables, settings, samples, level),
        "<h4>Number of variants table</h4>",
        _genotype_table(tables, samples, level),
    ]
    if len(samples) > 1 and level < 2:
        parts.append("<h4>Allelic drop-out (ADO) &amp; allelic drop-in (ADI)</h4>")
        parts.append(_ado_adi(tables, samples, level))
    parts.append("<h4>Variant depth</h4>")
    parts.append(
        _grid([_figure({"kind": "depth", "level": level, "sample": s}, 200) for s in samples], 4)
    )
    parts.append("<h4>Number of variants profile</h4>")
    parts.append(_grid([_figure({"kind": "density", "level": level}, 240)], 1))
    return "".join(parts)


def _body(
    settings: Settings,
    tables: dict[str, pl.DataFrame],
    samples: tuple[str, ...],
    chromosomes: list[str],
) -> str:
    """Assemble every report section in documented filter order."""
    outline = _Outline()
    parts: list[str] = []
    if settings.info.strip():
        parts.append(outline.heading(2, "Family/disease information"))
        parts.append(f'<p class="family-info">{escape(settings.info)}</p>')
    if len(samples) > 1:
        parts.append(outline.heading(2, "Family tree"))
        parts.append(f'<div class="pedigree">{pedigree_svg(settings)}</div>')

    parts.append(outline.heading(2, FILTER_TITLES[0]))
    parts.append(_statistics_block(tables, settings, samples, 0, outline))
    parts.append(outline.heading(3, "Vcf-based copy number (bam-based verification recommended)"))
    parts.append(
        _grid([_figure({"kind": "cn", "sample": sample}, 210) for sample in samples], 1)
    )

    parts.append(outline.heading(2, FILTER_TITLES[1]))
    parts.append(_statistics_block(tables, settings, samples, 1, outline))
    if settings.regions and "baf" in tables:
        parts.append(outline.heading(3, "B-allele frequency (BAF), region(s) of interest"))
        for region in settings.regions:
            parts.append(f"<h4>{escape(region)}</h4>")
            parts.append(
                _grid(
                    [
                        _figure({"kind": "rbaf", "region": region, "sample": sample}, 300)
                        for sample in samples
                    ],
                    4,
                )
            )
    baf_samples = [sample for sample in settings.baf_ids if sample in samples]
    if baf_samples and "baf" in tables:
        suffix = (
            f", only {settings.value_of_p * 100:g}% of data" if settings.limit_baf_to_p else ""
        )
        parts.append(outline.heading(3, f"B-allele frequency (BAF), genome-wide{suffix}"))
        for sample in baf_samples:
            parts.append(f"<h4>{escape(sample_label(settings, sample))}</h4>")
            parts.append(
                _grid(
                    [
                        _figure({"kind": "gbaf", "sample": sample, "chrom": chrom}, 240)
                        for chrom in chromosomes
                    ],
                    2,
                )
            )
    mendelian = tables.get("mendelian")
    if mendelian is not None and not mendelian.is_empty():
        children = [
            sample for sample in samples if sample in set(mendelian["sample"].to_list())
        ]
        parts.append(outline.heading(3, "Mendelian errors"))
        parts.append(
            _grid([_figure({"kind": "men", "sample": child}, 210) for child in children], 1)
        )
    mapping = tables.get("parent_mapping")
    if mapping is not None and not mapping.is_empty():
        suffix = f", only {settings.value_of_p * 100:g}% of data" if settings.limit_pm_to_p else ""
        parts.append(outline.heading(3, f"Parent mapping{suffix}"))
        children = [sample for sample in samples if sample in set(mapping["child"].to_list())]
        for child in children:
            parts.append(f"<h4>{escape(sample_label(settings, child))}</h4>")
            panels = [
                _figure({"kind": "pm", "sample": child, "chrom": chrom}, 260)
                for chrom in chromosomes
            ]
            panels.append(_figure({"kind": "pmlegend", "sample": child}, 260))
            parts.append(_grid(panels, 4))

    parts.append(outline.heading(2, FILTER_TITLES[2]))
    parts.append(_statistics_block(tables, settings, samples, 2, outline))
    haplotypes = tables.get("haplotypes")
    if haplotypes is not None and not haplotypes.is_empty():
        parts.append(outline.heading(3, "Haplotyping by Merlin"))
        height = 60 * len(samples) + 90
        drawn = [chrom for chrom in chromosomes if chrom in set(haplotypes["chrom"].to_list())]
        parts.append(
            _grid([_figure({"kind": "hap", "chrom": chrom}, height) for chrom in drawn], 2)
        )
        concordance = _concordance_table(tables, samples)
        if concordance:
            parts.append(outline.heading(3, "Haplotyping by Merlin: strand concordance"))
            parts.append(concordance)
    return outline.toc() + "".join(parts)


def render_report(
    output: Path,
    settings: Settings,
    tables: dict[str, pl.DataFrame],
    samples: tuple[str, ...],
    cytobands: tuple[Cytoband, ...],
) -> Path:
    """Write one self-contained Plotly report with a compressed data payload."""
    sizes = chromosome_sizes(cytobands)
    chromosomes = [chrom for chrom in CHROMOSOMES if chrom in sizes]
    payload: dict[str, object] = {
        name: _table_payload(frame)
        for name, frame in tables.items()
        if not frame.is_empty()
    }
    payload["meta"] = _meta(settings, tables, samples, cytobands)
    encoded = base64.b64encode(
        gzip.compress(
            json.dumps(payload, separators=(",", ":"), allow_nan=False).encode(), compresslevel=9
        )
    ).decode("ascii")
    html = (
        "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">"
        f"<title>{escape(settings.family.id)}</title>"
        f"<style>{_inline('report.css', 'style')}</style></head><body>"
        f"<h1>{escape(settings.family.id)}</h1>"
        + _body(settings, tables, samples, chromosomes)
        + f'<script id="hopla-data" type="application/gzip+json">{encoded}</script>'
        + f"<script>{_inline('plotly-basic.min.js', 'script')}</script>"
        + f"<script>{_inline('report.js', 'script')}</script>"
        + "</body></html>"
    )
    output.write_text(html, encoding="utf-8")
    return output
