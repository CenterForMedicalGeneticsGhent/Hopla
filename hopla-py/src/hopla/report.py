"""Create a compact offline report with virtual tables and canvas plots."""

from __future__ import annotations

import base64
import gzip
import json
from html import escape
from pathlib import Path
from typing import Any

import polars as pl

from hopla.analysis import iter_nonempty
from hopla.pedigree import pedigree_svg
from hopla.settings import Settings

SECTION_TITLES = {
    "variant_stats": "Filter 0/1/2: variant statistics",
    "ado_adi": "Allelic drop-out (ADO) and drop-in (ADI)",
    "baf": "B-allele frequency (BAF)",
    "copy_number": "VCF-based copy number",
    "cn_segments": "Copy-number segments",
    "mendelian": "Mendelian errors",
    "parent_mapping": "Parent mapping",
    "haplotypes": "Haplotyping by Merlin",
}


def _json_value(value: Any) -> Any:
    """Normalize Polars scalar values for standards-compliant JSON."""
    if isinstance(value, float) and (value != value or value in (float("inf"), float("-inf"))):
        return None
    return value


def _table_payload(frame: pl.DataFrame) -> dict[str, object]:
    """Encode a DataFrame column-wise and cap only initial table preview rows."""
    return {
        "columns": frame.columns,
        "data": {
            name: [_json_value(value) for value in frame[name].to_list()] for name in frame.columns
        },
        "rows": frame.height,
    }


def render_report(
    output: Path,
    settings: Settings,
    tables: dict[str, pl.DataFrame],
) -> Path:
    """Write one self-contained report with a gzip-compressed columnar payload."""
    payload = {name: _table_payload(frame) for name, frame in iter_nonempty(tables)}
    encoded = base64.b64encode(
        gzip.compress(
            json.dumps(payload, separators=(",", ":"), allow_nan=False).encode(), compresslevel=9
        )
    ).decode("ascii")
    information = "".join(f"<p>{escape(line)}</p>" for line in settings.info)
    sections = "".join(
        f'<section id="{escape(name)}"><h2>{escape(SECTION_TITLES.get(name, name))}</h2>'
        f'<div class="view" data-table="{escape(name)}"></div></section>'
        for name in payload
    )
    html = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>{escape(settings.fam_id)} — Hopla report</title>
<style>
:root{{font-family:system-ui,sans-serif;color:#172033;background:#f5f7fb}}body{{margin:auto;max-width:1400px;padding:24px}}
h1,h2{{color:#172554}}section,header{{background:white;border:1px solid #dbe2ec;border-radius:12px;padding:18px;margin:16px 0}}
.table{{overflow:auto;max-height:420px}}table{{border-collapse:collapse;width:100%;font-size:12px}}th,td{{padding:5px 8px;border-bottom:1px solid #e5e7eb;text-align:left;white-space:nowrap}}th{{position:sticky;top:0;background:#eef2ff}}
canvas{{width:100%;height:260px;border:1px solid #e5e7eb}}.meta{{color:#64748b;font-size:12px}}
</style></head><body><header><h1>Hopla: {escape(settings.fam_id)}</h1>{information}{pedigree_svg(settings)}</header>
{sections}<script id="hopla-data" type="application/gzip+json">{encoded}</script>
<script>
(async()=>{{const e=document.querySelector("#hopla-data"),b=atob(e.textContent.trim()),a=new Uint8Array(b.length);
for(let i=0;i<b.length;i++)a[i]=b.charCodeAt(i);const stream=new Blob([a]).stream().pipeThrough(new DecompressionStream("gzip"));
const tables=JSON.parse(await new Response(stream).text());
function table(el,t){{const n=Math.min(t.rows,500),wrap=document.createElement("div");wrap.className="table";
const out=document.createElement("table"),head=out.createTHead().insertRow();t.columns.forEach(c=>head.insertCell().textContent=c);
const body=out.createTBody();for(let r=0;r<n;r++){{const row=body.insertRow();t.columns.forEach(c=>row.insertCell().textContent=t.data[c][r]??"");}}
wrap.append(out);el.append(wrap);const meta=document.createElement("p");meta.className="meta";meta.textContent=`${{t.rows.toLocaleString()}} rows${{t.rows>n?" (first 500 shown)":""}}`;el.append(meta);}}
function plot(el,t){{const x=t.data.pos||t.data.start,y=t.data.af||t.data.log2_ratio;if(!x||!y)return;const c=document.createElement("canvas"),d=devicePixelRatio||1;
c.width=1200*d;c.height=260*d;const g=c.getContext("2d");g.scale(d,d);g.fillStyle="#fff";g.fillRect(0,0,1200,260);
const valid=y.map((v,i)=>v===null?null:[x[i],v]).filter(Boolean),step=Math.max(1,Math.ceil(valid.length/20000));
if(!valid.length)return;const xmin=Math.min(...valid.map(v=>v[0])),xmax=Math.max(...valid.map(v=>v[0])),ymin=Math.min(...valid.map(v=>v[1])),ymax=Math.max(...valid.map(v=>v[1]));
g.fillStyle="#2563eb99";for(let i=0;i<valid.length;i+=step){{const v=valid[i],px=10+(v[0]-xmin)/(xmax-xmin||1)*1180,py=250-(v[1]-ymin)/(ymax-ymin||1)*240;g.fillRect(px,py,2,2);}}el.append(c);}}
document.querySelectorAll("[data-table]").forEach(el=>{{const t=tables[el.dataset.table];plot(el,t);table(el,t);}});}})();
</script></body></html>"""
    output.write_text(html, encoding="utf-8")
    return output
