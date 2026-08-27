# Hopla Python

Typed Python implementation of the Hopla genomic family-analysis engine.

```bash
hopla run settings.yaml family.vcf.gz
hopla convert legacy-settings.txt
hopla concordance family-a-flow.txt family-b-flow.txt
hopla transform family-a-flow.txt family-b-flow.txt 1
```

The command validates settings before reading the VCF and writes a compact,
offline HTML report. Merlin 1.1.2 remains an optional external dependency.
