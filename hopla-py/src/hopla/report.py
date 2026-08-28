"""Render the self-contained Plotly report that mirrors the original R output."""

from __future__ import annotations

import base64
import gzip
import json
from html import escape
from importlib.util import find_spec
from pathlib import Path
from typing import Any

import polars as pl

from hopla.analysis import iter_nonempty
from hopla.cytobands import chromosome_sizes
from hopla.models import CHROMOSOMES, Cytoband
from hopla.pedigree import pedigree_svg, sample_label
from hopla.settings import Settings

# RColorBrewer "Paired", the palette the R engine used for every figure.
PALETTE = (
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
REPORT_FONT = 'system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif'
GENOTYPES = ("0/0", "0/1", "1/1")
FILTER_TITLES = (
    "Filter 0: single nucleotide variants",
    "Filter 1: filter 0, --dp_hard_limit, af_hard_limit and --dp_soft_limit",
    "Filter 2: filter 0, filter 1, keep_informative_ids and --keep_hetero_ids",
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


def _plotly_source() -> str:
    """Read the offline plotly.js bundle shipped inside the plotly package."""
    located = find_spec("plotly")
    if located is None or located.origin is None:
        raise RuntimeError("The plotly package is required to render the report.")
    bundle = Path(located.origin).parent / "package_data" / "plotly.min.js"
    if not bundle.is_file():
        raise RuntimeError(f"Could not find the offline plotly.js bundle at {bundle}.")
    return bundle.read_text(encoding="utf-8").replace("</script", "<\\/script")


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
        chrom, interval = region.split(":")
        start, end = (int(value) for value in interval.split("-"))
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
            "father": settings.father_ids[settings.sample_ids.index(sample)],
            "mother": settings.mother_ids[settings.sample_ids.index(sample)],
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
    """Render the genome-wide and per-region variant counts as text."""
    frame = tables.get("variant_stats")
    if frame is None or frame.is_empty():
        return ""

    def line(prefix: str, region: str) -> str:
        """Format one count line across all samples."""
        values = " | ".join(
            f"{sample}: {_count(frame, level, sample, region):,.0f}" for sample in samples
        )
        return f"<p>° {escape(prefix)}; {escape(values)}</p>"

    parts = [line("overall", "genome")]
    for region in settings.regions:
        parts.append(line(f"in {region}", region))
        parts.append(line(f"in {region} (left flank)", f"{region} (left flank)"))
        parts.append(line(f"in {region} (right flank)", f"{region} (right flank)"))
    return "".join(parts)


def _genotype_table(tables: dict[str, pl.DataFrame], samples: tuple[str, ...], level: int) -> str:
    """Render the pairwise genotype-count grid of the original report."""
    frame = tables.get("genotype_pairs")
    if frame is None or frame.is_empty():
        return ""
    counts = {
        (str(row["sample_a"]), str(row["sample_b"]), str(row["genotype_a"]), str(row["genotype_b"])): int(row["count"])
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
    """Render allelic drop-out and drop-in percentages per child."""
    frame = tables.get("ado_adi")
    parts = []
    for sample in samples:
        parts.append(f"<h5>{escape(sample)}</h5>")
        matched = (
            frame.filter((pl.col("filter_level") == level) & (pl.col("sample") == sample))
            if frame is not None and not frame.is_empty()
            else None
        )
        if matched is None or matched.is_empty():
            parts.append("<p>no two parents provided</p>")
            continue
        values = {str(row["metric"]): row["value"] for row in matched.iter_rows(named=True)}
        for metric in ("ADO", "ADI"):
            value = values.get(metric)
            text = "NA" if value is None else f"{value}%"
            parts.append(f"<p>{metric} = {text}</p>")
    return "".join(parts)


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
    tables: dict[str, pl.DataFrame], settings: Settings, samples: tuple[str, ...], level: int
) -> str:
    """Render the shared variant-statistics block of one filter stage."""
    parts = [
        "<h3>Variant statistics</h3>",
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
    """Assemble every report section in the order the R engine used."""
    parts: list[str] = []
    if settings.info:
        parts.append("<h2>Family/disease information</h2>")
        parts.extend(f"<p>{escape(line)}</p>" for line in settings.info)
    if len(samples) > 1:
        parts.append("<h2>Family tree</h2>")
        parts.append(f'<div class="pedigree">{pedigree_svg(settings)}</div>')

    parts.append(f"<h2>{escape(FILTER_TITLES[0])}</h2>")
    parts.append(_statistics_block(tables, settings, samples, 0))
    parts.append("<h3>Vcf-based copy number (bam-based verification recommended)</h3>")
    parts.append(
        _grid([_figure({"kind": "cn", "sample": sample}, 210) for sample in samples], 1)
    )

    parts.append(f"<h2>{escape(FILTER_TITLES[1])}</h2>")
    parts.append(_statistics_block(tables, settings, samples, 1))
    if settings.regions and "baf" in tables:
        parts.append("<h3>B-allele frequency (BAF), region(s) of interest</h3>")
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
        parts.append(f"<h3>B-allele frequency (BAF), genome-wide{escape(suffix)}</h3>")
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
        parts.append("<h3>Mendelian errors</h3>")
        parts.append(
            _grid([_figure({"kind": "men", "sample": child}, 210) for child in children], 1)
        )
    mapping = tables.get("parent_mapping")
    if mapping is not None and not mapping.is_empty():
        suffix = f", only {settings.value_of_p * 100:g}% of data" if settings.limit_pm_to_p else ""
        parts.append(f"<h3>Parent mapping{escape(suffix)}</h3>")
        children = [sample for sample in samples if sample in set(mapping["child"].to_list())]
        for child in children:
            parts.append(f"<h4>{escape(sample_label(settings, child))}</h4>")
            panels = [
                _figure({"kind": "pm", "sample": child, "chrom": chrom}, 260)
                for chrom in chromosomes
            ]
            panels.append(_figure({"kind": "pmlegend", "sample": child}, 260))
            parts.append(_grid(panels, 4))

    parts.append(f"<h2>{escape(FILTER_TITLES[2])}</h2>")
    parts.append(_statistics_block(tables, settings, samples, 2))
    haplotypes = tables.get("haplotypes")
    if haplotypes is not None and not haplotypes.is_empty():
        parts.append("<h3>Haplotyping by Merlin</h3>")
        height = 60 * len(samples) + 90
        drawn = [chrom for chrom in chromosomes if chrom in set(haplotypes["chrom"].to_list())]
        parts.append(
            _grid([_figure({"kind": "hap", "chrom": chrom}, height) for chrom in drawn], 2)
        )
        concordance = _concordance_table(tables, samples)
        if concordance:
            parts.append("<h3>Haplotyping by Merlin: strand concordance</h3>")
            parts.append(concordance)
    return "".join(parts)


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
        name: _table_payload(frame) for name, frame in iter_nonempty(tables)
    }
    payload["meta"] = _meta(settings, tables, samples, cytobands)
    encoded = base64.b64encode(
        gzip.compress(
            json.dumps(payload, separators=(",", ":"), allow_nan=False).encode(), compresslevel=9
        )
    ).decode("ascii")
    html = (
        "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">"
        f"<title>{escape(settings.fam_id)}</title>"
        f"<style>{_STYLE}</style></head><body>"
        f"<h1>{escape(settings.fam_id)}</h1>"
        + _body(settings, tables, samples, chromosomes)
        + f'<script id="hopla-data" type="application/gzip+json">{encoded}</script>'
        + f"<script>{_plotly_source()}</script>"
        + f"<script>{_SCRIPT}</script>"
        + "</body></html>"
    )
    output.write_text(html, encoding="utf-8")
    return output


_STYLE = """
body{font-family:system-ui,-apple-system,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif;color:#0f172a;margin:0 auto;padding:24px 32px 96px;max-width:1600px;line-height:1.45}
h1{font-size:22px;margin:0 0 24px}
h2{font-size:19px;margin:44px 0 12px;padding-top:16px;border-top:2px solid #0f172a}
h3{font-size:16px;margin:28px 0 8px}
h4{font-size:14px;margin:20px 0 6px;color:#334155}
h5{font-size:13px;margin:12px 0 2px;color:#475569}
p{margin:2px 0;font-size:13px}
.grid{display:grid;grid-template-columns:repeat(var(--cols),minmax(0,1fr));gap:6px;margin:8px 0 4px}
.fig{min-width:0;background:#fff}
.pedigree{margin:12px 0 8px;overflow-x:auto}
.pedigree svg{max-width:100%;height:auto}
table.matrix{border-collapse:collapse;font-size:11px;margin:6px 0 10px}
table.matrix th,table.matrix td{border:1px solid #cbd5f5;padding:3px 7px;text-align:right;white-space:nowrap}
table.matrix th{font-weight:600;text-align:center}
table.matrix th.block0{background:#A6CEE3}
table.matrix th.block1{background:#1F78B4;color:#fff}
table.matrix td.empty{background:#f8fafc;border-color:#eef2f7}
"""

_SCRIPT = r"""
(function(){
  var node = document.getElementById('hopla-data');
  var binary = atob(node.textContent.trim());
  var bytes = new Uint8Array(binary.length);
  for (var i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  var stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'));
  new Response(stream).text().then(function(text){ start(JSON.parse(text)); });

  function start(D){
    var M = D.meta, P = M.palette, LC = M.letterColors, MARK = M.markColor;
    var CHRS = M.chromosomes, SIZES = M.sizes;
    var OFF = {}, GENOME = 0;
    CHRS.forEach(function(c){ OFF[c] = GENOME; GENOME += SIZES[c]; });
    var CONFIG = {responsive:true, displaylogo:false, displayModeBar:'hover'};

    function fmt(v){ return Math.round(v).toLocaleString('en-US'); }
    function has(name){ return D[name] && D[name].rows; }
    function where(name, keep){
      var t = D[name], out = [];
      if (!t) return out;
      for (var i = 0; i < t.rows; i++) if (keep(t.data, i)) out.push(i);
      return out;
    }
    function pick(values, index){
      var out = new Array(index.length);
      for (var i = 0; i < index.length; i++) out[i] = values[index[i]];
      return out;
    }
    function extent(values){
      var lo = Infinity, hi = -Infinity;
      for (var i = 0; i < values.length; i++){
        var v = values[i];
        if (v === null || !isFinite(v)) continue;
        if (v < lo) lo = v;
        if (v > hi) hi = v;
      }
      return [lo, hi];
    }
    function translucent(hex){
      var value = parseInt(hex.slice(1), 16);
      return 'rgba(' + [(value >> 16) & 255, (value >> 8) & 255, value & 255].join(',') + ',0.2)';
    }
    function thin(index, fraction){
      if (!fraction || fraction >= 1 || index.length < 20) return index;
      var step = Math.max(1, Math.round(1 / fraction)), out = [];
      for (var i = 0; i < index.length; i += step) out.push(index[i]);
      return out;
    }

    function layout(options){
      return {
        height: options.height,
        margin: options.margin || {l:58, r:14, t:14, b:30},
        showlegend: false,
        hovermode: options.hovermode || 'closest',
        font: {family: M.font, size: 11},
        paper_bgcolor: '#fff',
        plot_bgcolor: '#fff',
        xaxis: Object.assign({title:{text: options.xtitle || '', standoff: 2}, zeroline:false, showgrid:false, showticklabels:false}, options.xaxis || {}),
        yaxis: Object.assign({title:{text: options.ytitle || '', standoff: 2}, zeroline:false, showgrid:false}, options.yaxis || {}),
        shapes: options.shapes || [],
        annotations: options.annotations || []
      };
    }

    function chromosomeAxis(){
      return {
        showticklabels: true,
        tickmode: 'array',
        tickvals: CHRS.map(function(c){ return OFF[c] + SIZES[c] / 2; }),
        ticktext: CHRS.map(function(c){ return c.replace('chr',''); }),
        tickfont: {size: 9},
        range: [0, GENOME]
      };
    }

    function chromosomeShapes(lo, hi){
      var shapes = CHRS.map(function(c){
        return {type:'line', x0:OFF[c], x1:OFF[c], y0:lo, y1:hi, line:{color:'#0f172a', width:0.5}};
      });
      shapes.push({type:'line', x0:GENOME, x1:GENOME, y0:lo, y1:hi, line:{color:'#0f172a', width:0.5}});
      return shapes;
    }

    function regionShapes(lo, hi, chrom, flanks){
      var shapes = [];
      M.regions.forEach(function(region){
        if (chrom && region.chrom !== chrom) return;
        var base = chrom ? 0 : OFF[region.chrom];
        if (base === undefined) return;
        [region.start, region.end].forEach(function(position){
          shapes.push({type:'line', x0:base+position, x1:base+position, y0:lo, y1:hi, line:{color:MARK, width:1.2}});
        });
        if (flanks === false) return;
        [region.start - M.flank, region.end + M.flank].forEach(function(position){
          shapes.push({type:'line', x0:base+position, x1:base+position, y0:lo, y1:hi, line:{color:MARK, width:0.8, dash:'dot'}});
        });
      });
      return shapes;
    }

    function cytobandShapes(chrom, y, thickness){
      var bands = M.cytobands[chrom], shapes = [];
      if (!bands) return shapes;
      for (var i = 0; i < bands.start.length; i++){
        var stain = bands.stain[i] || '';
        var special = stain.indexOf('acen') >= 0 || stain.indexOf('gvar') >= 0 || stain.indexOf('stalk') >= 0;
        shapes.push({
          type:'rect', x0:bands.start[i], x1:bands.end[i],
          y0:y - thickness/2, y1:y + thickness/2,
          fillcolor: special ? '#111827' : (i % 2 ? '#a9a9a9' : '#d3d3d3'),
          line:{width:0}
        });
      }
      return shapes;
    }

    function runs(letters, positions){
      var blocks = [], start = 0, i;
      for (i = 1; i <= letters.length; i++){
        if (i === letters.length || letters[i] !== letters[start]){
          blocks.push({letter: letters[start], last: i - 1});
          start = i;
        }
      }
      var edges = [positions[0]];
      for (i = 0; i < blocks.length - 1; i++){
        var last = blocks[i].last;
        edges.push(positions[last] + (positions[last + 1] - positions[last]) / 2);
      }
      edges.push(positions[positions.length - 1]);
      return blocks.map(function(block, index){
        return {letter: block.letter, start: edges[index], end: edges[index + 1]};
      });
    }

    var BUILD = {};

    BUILD.depth = function(spec){
      var d = D.variant_depth.data;
      var mine = where('variant_depth', function(d, i){ return d.filter_level[i] === spec.level && d.sample[i] === spec.sample; });
      var level = where('variant_depth', function(d, i){ return d.filter_level[i] === spec.level; });
      var counts = extent(pick(d.count, level));
      return {
        traces: [{type:'bar', x: pick(d.depth, mine), y: pick(d.count, mine), hoverinfo:'x+y', marker:{color:P[0]}}],
        layout: layout({
          height: spec.height, xtitle: M.labels[spec.sample], ytitle: 'density',
          xaxis: {showticklabels:true, range:[extent(pick(d.bin_start, level))[0], extent(pick(d.bin_end, level))[1]]},
          yaxis: {range:[0, Math.max(1, counts[1])]}
        })
      };
    };

    BUILD.density = function(spec){
      var d = D.variant_density.data, sample = M.samples[0];
      var mine = where('variant_density', function(d, i){ return d.filter_level[i] === spec.level && d.sample[i] === sample; });
      var x = [], y = [], text = [];
      mine.forEach(function(i){
        var chrom = d.chrom[i];
        if (OFF[chrom] === undefined) return;
        x.push(OFF[chrom] + d.start[i]);
        y.push(d.count[i]);
        text.push(chrom + ':' + fmt(d.start[i]) + '-' + fmt(d.end[i]));
      });
      var top = extent(y)[1] || 1, range = [-top * 0.1, top * 1.1];
      return {
        traces: [{type:'scatter', mode:'markers', x:x, y:y, text:text, hoverinfo:'y+text',
                  marker:{color:P[0], size:M.dot * 2, opacity:0.6}}],
        layout: layout({
          height: spec.height, ytitle: 'variant count', hovermode: 'x unified',
          xaxis: chromosomeAxis(), yaxis: {range: range},
          shapes: chromosomeShapes(range[0], range[1]).concat(regionShapes(range[0], range[1], null, true))
        })
      };
    };

    BUILD.cn = function(spec){
      var d = D.copy_number.data;
      var mine = where('copy_number', function(d, i){ return d.sample[i] === spec.sample; });
      var x = [], y = [], text = [];
      mine.forEach(function(i){
        var chrom = d.chrom[i], value = d.log2_ratio[i];
        if (OFF[chrom] === undefined || value === null || !isFinite(value)) return;
        x.push(OFF[chrom] + d.start[i]);
        y.push(value);
        text.push(chrom + ':' + fmt(d.start[i]) + '-' + fmt(d.end[i]));
      });
      var span = extent(y);
      var range = [Math.min(-2.25, span[0]), Math.max(2.25, span[1])];
      var traces = [{type:'scatter', mode:'markers', x:x, y:y, text:text, hoverinfo:'y+text',
                     marker:{color:P[0], size:M.dot * 2, opacity:0.6}}];
      if (has('cn_segments')){
        var s = D.cn_segments.data;
        where('cn_segments', function(s, i){ return s.sample[i] === spec.sample; }).forEach(function(i){
          var chrom = s.chrom[i];
          if (OFF[chrom] === undefined) return;
          traces.push({
            type:'scatter', mode:'lines',
            x:[OFF[chrom] + s.start[i], OFF[chrom] + s.end[i]],
            y:[s.seg_mean[i], s.seg_mean[i]],
            hoverinfo:'text',
            text:'segment: ' + chrom + ':' + fmt(s.start[i]) + '-' + fmt(s.end[i]),
            line:{color:P[1], width:M.dot}
          });
        });
      }
      return {
        traces: traces,
        layout: layout({
          height: spec.height, xtitle: M.labels[spec.sample], ytitle: 'log2(ratio)',
          xaxis: chromosomeAxis(), yaxis: {range: range},
          shapes: chromosomeShapes(range[0], range[1]).concat(regionShapes(range[0], range[1], null, true))
        })
      };
    };

    function bafTrace(index, d){
      return {
        type:'scatter', mode:'markers',
        x: pick(d.pos, index),
        y: index.map(function(i){ return d.af[i] * 100; }),
        text: index.map(function(i){ return d.chrom[i] + ':' + fmt(d.pos[i]); }),
        hoverinfo:'y+text',
        marker:{color:P[0], size:M.dot * 2, opacity:0.6}
      };
    }

    BUILD.rbaf = function(spec){
      var d = D.baf.data;
      var region = M.regions.filter(function(r){ return r.label === spec.region; })[0];
      var from = Math.max(1, region.start - M.flank);
      var to = Math.min(SIZES[region.chrom], region.end + M.flank);
      var mine = where('baf', function(d, i){
        return d.sample[i] === spec.sample && d.chrom[i] === region.chrom && d.pos[i] > from && d.pos[i] < to;
      });
      return {
        traces: [bafTrace(mine, d)],
        layout: layout({
          height: spec.height, ytitle: 'BAF (%)',
          xaxis: {range:[from, to]}, yaxis: {range:[-15, 115], fixedrange:true},
          shapes: regionShapes(-5, 105, region.chrom, false),
          annotations: [{x:(from + to) / 2, y:-10, text:M.labels[spec.sample], showarrow:false, font:{size:11}}]
        })
      };
    };

    BUILD.gbaf = function(spec){
      var d = D.baf.data;
      var mine = thin(where('baf', function(d, i){
        return d.sample[i] === spec.sample && d.chrom[i] === spec.chrom;
      }), M.limitBaf);
      return {
        traces: [bafTrace(mine, d)],
        layout: layout({
          height: spec.height, ytitle: 'BAF (%)',
          xaxis: {range:[0, SIZES[spec.chrom]]}, yaxis: {range:[-15, 132], fixedrange:true},
          shapes: cytobandShapes(spec.chrom, 124, 8).concat(regionShapes(-5, 118, spec.chrom, true)),
          annotations: [{x:SIZES[spec.chrom] / 2, y:-10, text:spec.chrom, showarrow:false, font:{size:11}}]
        })
      };
    };

    BUILD.men = function(spec){
      var d = D.mendelian.data;
      var mine = where('mendelian', function(d, i){ return d.sample[i] === spec.sample; });
      // Window rows arrive grouped, so order them before drawing connected lines.
      var at = function(i){ return OFF[d.chrom[i]] === undefined ? null : OFF[d.chrom[i]] + d.start[i]; };
      mine = mine.filter(function(i){ return at(i) !== null; }).sort(function(a, b){ return at(a) - at(b); });
      var x = [], text = [];
      mine.forEach(function(i){
        x.push(at(i));
        text.push(d.chrom[i] + ':' + fmt(d.start[i]) + '-' + fmt(d.end[i]));
      });
      var traces = [], top = 50;
      [['trio', P[0], 'solid', 'trio errors'],
       ['father', P[1], 'dot', 'father errors'],
       ['mother', P[2], 'dot', 'mother errors']].forEach(function(entry){
        if (!d[entry[0]]) return;
        var y = pick(d[entry[0]], mine);
        var span = extent(y);
        if (span[1] > top) top = span[1];
        traces.push({type:'scatter', mode:'lines', x:x, y:y, text:text, name:entry[3], hoverinfo:'name+y+text',
                     line:{color:entry[1], width:M.dot, dash:entry[2]}, fill:'tozeroy',
                     fillcolor:translucent(entry[1])});
      });
      var range = [0, top];
      return {
        traces: traces,
        layout: layout({
          height: spec.height, xtitle: M.labels[spec.sample], ytitle: 'mendelian error count',
          xaxis: chromosomeAxis(), yaxis: {range: range},
          shapes: chromosomeShapes(range[0], range[1]).concat(regionShapes(range[0], range[1], null, true))
        })
      };
    };

    BUILD.pm = function(spec){
      var d = D.parent_mapping.data;
      var mine = thin(where('parent_mapping', function(d, i){
        return d.child[i] === spec.sample && d.chrom[i] === spec.chrom;
      }), M.limitPm);
      var x = [], y = [], color = [], text = [];
      mine.forEach(function(i){
        var father = d.origin[i] === 'father';
        var het = d.zygosity[i] === 'heterozygous';
        x.push(d.pos[i]);
        y.push(father ? (het ? 5 : 4) : (het ? 2 : 1));
        color.push(father ? P[0] : P[1]);
        text.push(d.chrom[i] + ':' + fmt(d.pos[i]));
      });
      return {
        traces: [{type:'scatter', mode:'markers', x:x, y:y, text:text, hoverinfo:'text',
                  marker:{color:color, size:M.dot * 3, symbol:'cross-thin-open', line:{color:color, width:1}}}],
        layout: layout({
          height: spec.height, xtitle: spec.chrom,
          xaxis: {range:[0, SIZES[spec.chrom]]},
          yaxis: {range:[0.5, 6], fixedrange:true, showticklabels:false},
          shapes: cytobandShapes(spec.chrom, 3, 0.25).concat(regionShapes(0.5, 5.5, spec.chrom, true))
        })
      };
    };

    BUILD.pmlegend = function(spec){
      var father = M.parents && M.parents[spec.sample] ? M.parents[spec.sample].father : null;
      var mother = M.parents && M.parents[spec.sample] ? M.parents[spec.sample].mother : null;
      var labels;
      if (father && mother){
        labels = ['father 0/1 --- mother 0/0|1/1 --- child 0/1',
                  'father 0/1 --- mother 0/0|1/1 --- child 0/0|1/1',
                  'father 0/0|1/1 --- mother 0/1 --- child 0/1',
                  'father 0/0|1/1 --- mother 0/1 --- child 0/0|1/1'];
      } else if (father){
        labels = ['father 0/1 --- child 0/1', 'father 0/1 --- child 0/0|1/1',
                  'father 0/0|1/1 --- child 0/1', 'father 0/0|1/1 --- child 0/0|1/1'];
      } else {
        labels = ['mother 0/0|1/1 --- child 0/1', 'mother 0/0|1/1 --- child 0/0|1/1',
                  'mother 0/1 --- child 0/1', 'mother 0/1 --- child 0/0|1/1'];
      }
      var rows = [[5, labels[0], P[0]], [4, labels[1], P[0]], [2, labels[2], P[1]], [1, labels[3], P[1]]];
      return {
        traces: [{type:'scatter', mode:'markers', x:[0], y:[0], hoverinfo:'none', marker:{color:'#fff', size:0.1}}],
        layout: layout({
          height: spec.height,
          xaxis: {range:[0, 1]}, yaxis: {range:[0.5, 6], fixedrange:true, showticklabels:false},
          annotations: rows.map(function(row){
            return {x:0.5, y:row[0], text:row[1], showarrow:false, font:{size:10, color:row[2]}};
          })
        })
      };
    };

    BUILD.hap = function(spec){
      var d = D.haplotypes.data;
      var count = M.samples.length;
      var inChromosome = where('haplotypes', function(d, i){ return d.chrom[i] === spec.chrom; });
      var traces = [], annotations = [];
      var regionChromosome = M.regions.some(function(region){ return region.chrom === spec.chrom; });
      var showPoints = M.keepChromosomesOnly || M.keepRegionsOnly ? regionChromosome : true;
      M.samples.forEach(function(sample, order){
        var base = count * 3 - (order + 1) * 3;
        annotations.push({x:0, y:base + 2, text:M.labels[sample], showarrow:false, xanchor:'left', font:{size:10}});
        [1, 2].forEach(function(strand){
          var mine = inChromosome.filter(function(i){ return d.sample[i] === sample && d.strand[i] === strand; });
          if (!mine.length) return;
          mine.sort(function(a, b){ return d.pos[a] - d.pos[b]; });
          var y = strand === 1 ? base + 1 : base;
          var positions = pick(d.pos, mine), letters = pick(d.letter, mine);
          var px = [], py = [], pc = [], pt = [], ps = [];
          mine.forEach(function(i){
            if (d.genotype[i] === 'NA') return;
            if (!showPoints) return;
            if (M.keepRegionsOnly && !M.regions.some(function(region){
              return region.chrom === spec.chrom && d.pos[i] >= region.start - M.flank && d.pos[i] <= region.end + M.flank;
            })) return;
            px.push(d.pos[i]);
            py.push(y);
            pc.push(LC[d.letter[i]] || '#ffffff');
            pt.push(spec.chrom + ':' + fmt(d.pos[i]) + ' (' + d.genotype[i] + ')');
            ps.push(d.is_corrected[i] ? 'circle' : 'square');
          });
          if (px.length){
            traces.push({type:'scatter', mode:'markers', x:px, y:py, text:pt, hoverinfo:'text',
                         marker:{color:pc, symbol:ps, size:M.dot * 4, line:{color:pc, width:1}}});
          }
          var blocks = runs(letters, positions);
          blocks.forEach(function(block){
            traces.push({type:'scatter', mode:'lines', x:[block.start, block.end], y:[y, y], hoverinfo:'none',
                         line:{color:LC[block.letter] || '#ffffff', width:M.dot * 2}});
          });
          var breaks = blocks.slice(1).map(function(block){ return block.start; });
          if (breaks.length){
            traces.push({type:'scatter', mode:'markers', x:breaks,
                         y:breaks.map(function(){ return y + (strand === 1 ? 0.3 : -0.3); }),
                         hoverinfo:'none',
                         marker:{symbol: strand === 1 ? 'y-down-open' : 'y-up-open', color:MARK, size:M.dot * 6}});
          }
        });
      });
      var ceiling = count * 3 + 1;
      return {
        traces: traces,
        layout: layout({
          height: spec.height, xtitle: spec.chrom,
          xaxis: {range:[0, SIZES[spec.chrom]]},
          yaxis: {range:[-1, ceiling + 1], fixedrange:true, showticklabels:false},
          annotations: annotations,
          shapes: cytobandShapes(spec.chrom, ceiling, 0.35).concat(regionShapes(-0.5, ceiling - 0.5, spec.chrom, true))
        })
      };
    };

    function draw(element){
      var spec = JSON.parse(element.getAttribute('data-spec'));
      spec.height = element.clientHeight || 240;
      var builder = BUILD[spec.kind];
      if (!builder) return;
      try {
        var figure = builder(spec);
        Plotly.newPlot(element, figure.traces, figure.layout, CONFIG);
      } catch (error){
        element.textContent = 'Could not render this figure.';
        console.error(spec, error);
      }
    }

    var observer = new IntersectionObserver(function(entries){
      entries.forEach(function(entry){
        if (!entry.isIntersecting) return;
        observer.unobserve(entry.target);
        draw(entry.target);
      });
    }, {rootMargin: '400px'});
    document.querySelectorAll('.fig').forEach(function(element){ observer.observe(element); });
  }
})();
"""
