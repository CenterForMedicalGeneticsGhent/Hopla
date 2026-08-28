# igv.js feasibility evaluation

Decision: do not embed igv.js in Hopla's default HTML report, and do not add an
`--igv-roi` implementation at this time.

This was evaluated against igv.js 3.8.5 in August 2026.

## Feasibility

igv.js can be embedded and has no JavaScript dependencies, but its minified
ES-module and script bundles are each approximately 1.43 MB before adding any
track or reference data. That fixed payload is materially larger than Hopla's
current report shell and conflicts with the requirement to keep output small.

More importantly, the [igv.js data-URI
documentation](https://igv.org/doc/igvjs/Data-URIs/) explicitly excludes
BigWig, BigBed, and TDF. Those indexed formats normally rely on HTTP range
requests. Consequently, the full-resolution BAF BigWigs produced by Hopla
cannot be placed in a self-contained report as ordinary data URIs.

Using `genome: "hg38"` also uses remote reference/genome services. Supplying a
fully offline reference instead would require additional sequence and index
assets, making a single-file report impractical. A CDN-based igv.js panel
would make a previously offline clinical report network-dependent.

## Usefulness

The useful igv.js case is locus context: genes, user-owned BAM/CRAM reads, and
Hopla BAF near a configured region. It does not replace Hopla's family-relative
haplotype colors, ADO/ADI calculations, concordance, filter tiers, or pedigree
views. Embedding a second genome browser would therefore duplicate only part
of the existing report.

An ROI-only implementation could convert BAF to gzipped bedGraph/WIG data
URIs, which igv.js supports. It was not implemented because it would still:

1. add the fixed 1.43 MB library bundle;
2. need a remote or separately packaged reference;
3. duplicate the report's existing region BAF interaction; and
4. create a second data representation beside Parquet and BigWig.

## Supported workflow

Hopla instead exports full-resolution BAF and quantitative data as BigWig,
categorical data as BED, copy-number segments as SEG, and a relative-path
`igv-session.xml`. Users can open that session in IGV desktop and add their
existing BAM/CRAM tracks without copying those sensitive, large files into the
Hopla report.

This keeps the HTML a single offline file. The `{fam_id}-export/` directory is
an optional interoperability export, not a required multi-file web
application.

## Conditions for reconsideration

Reconsider embedding only if one of these changes:

- igv.js offers a substantially smaller locus-only build;
- BigWig gains reliable in-memory `Blob`/data-URI random access;
- Hopla reports are routinely served over HTTP rather than opened offline; or
- user research shows the integrated alignment context outweighs the size and
  reference-data costs.

Sources:

- [igv.js data URIs](https://igv.org/doc/igvjs/Data-URIs/)
- [igv.js browser creation and reference configuration](https://igv.org/doc/igvjs/Browser-Creation/)
- [igv.js 3.8.5 distribution](https://cdn.jsdelivr.net/npm/igv@3.8.5/dist/)
