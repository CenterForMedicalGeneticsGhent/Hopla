"""Derive pedigree state and render a compact accessible SVG."""

from __future__ import annotations

from html import escape

import numpy as np

from hopla.models import CHROMOSOME_CODES, GenotypeMatrix, SiteTable
from hopla.settings import Gender, Settings


def predict_genders(settings: Settings, sites: SiteTable, matrix: GenotypeMatrix) -> list[Gender]:
    """Fill unknown genders from pedigree roles and chromosome depth ratios."""
    result = list(settings.genders)
    autosomal = sites.chrom <= 22
    x_mask = sites.chrom == CHROMOSOME_CODES["chrX"]
    y_mask = (
        (sites.chrom == CHROMOSOME_CODES["chrY"])
        & (sites.pos > 11_700_001)
        & (sites.pos < 21_800_000)
    )
    autosomal_mean = np.mean(matrix.dp[:, autosomal], axis=1)
    x_mean = (
        np.mean(matrix.dp[:, x_mask], axis=1)
        if np.any(x_mask)
        else np.full(len(matrix.samples), np.nan)
    )
    y_mean = (
        np.mean(matrix.dp[:, y_mask], axis=1)
        if np.any(y_mask)
        else np.full(len(matrix.samples), np.nan)
    )
    x_copies = np.divide(
        x_mean * 2,
        autosomal_mean,
        out=np.full(len(matrix.samples), np.nan),
        where=autosomal_mean > 0,
    )
    y_copies = np.divide(
        y_mean * 2,
        autosomal_mean,
        out=np.full(len(matrix.samples), np.nan),
        where=autosomal_mean > 0,
    )
    for sample in matrix.samples:
        index = settings.sample_ids.index(sample)
        if result[index] is not None:
            continue
        if sample in settings.mother_ids:
            result[index] = "F"
        elif sample in settings.father_ids:
            result[index] = "M"
        else:
            matrix_index = matrix.sample_index[sample]
            x_value, y_value = x_copies[matrix_index], y_copies[matrix_index]
            x_gender: Gender = (
                "M" if x_value < settings.x_cutoff else "F" if np.isfinite(x_value) else None
            )
            y_gender: Gender = (
                "F" if y_value < settings.y_cutoff else "M" if np.isfinite(y_value) else None
            )
            if x_gender is None and y_gender is None:
                raise ValueError(f"Could not predict gender for sample {sample}.")
            result[index] = y_gender if y_gender is not None else x_gender
    unresolved = [
        sample for sample, gender in zip(settings.sample_ids, result, strict=True) if gender is None
    ]
    if unresolved:
        raise ValueError(f"Gender must be provided for ghost sample(s): {', '.join(unresolved)}")
    return result


def add_ghosts(settings: Settings) -> Settings:
    """Add missing single parents as sequential U identifiers."""
    existing = [
        int(sample[1:])
        for sample in settings.sample_ids
        if sample[:1].upper() == "U" and sample[1:].isdigit()
    ]
    counter = max(existing, default=0)
    original_count = len(settings.sample_ids)
    for index in range(original_count):
        missing_father = settings.father_ids[index] is None
        missing_mother = settings.mother_ids[index] is None
        if missing_father == missing_mother:
            continue
        counter += 1
        ghost = f"U{counter}"
        if missing_father:
            settings.father_ids[index] = ghost
            gender: Gender = "M"
        else:
            settings.mother_ids[index] = ghost
            gender = "F"
        settings.sample_ids.append(ghost)
        settings.father_ids.append(None)
        settings.mother_ids.append(None)
        settings.genders.append(gender)
    return settings


def pedigree_svg(settings: Settings) -> str:
    """Render samples and parent links as a dependency-free SVG."""
    width = max(520, len(settings.sample_ids) * 110)
    nodes: list[str] = []
    links: list[str] = []
    locations = {
        sample: (60 + index * 105, 80 + (index % 2) * 90)
        for index, sample in enumerate(settings.sample_ids)
    }
    for sample, (x, y) in locations.items():
        index = settings.sample_ids.index(sample)
        for parent in (settings.father_ids[index], settings.mother_ids[index]):
            if parent in locations:
                px, py = locations[parent]
                links.append(f'<line x1="{px}" y1="{py + 18}" x2="{x}" y2="{y - 18}"/>')
        annotation = (
            "R"
            if sample in settings.reference_ids
            else "C"
            if sample in settings.carrier_ids
            else "A"
            if sample in settings.affected_ids
            else "N"
            if sample in settings.nonaffected_ids
            else ""
        )
        fill = "#fecaca" if annotation == "A" else "#e2e8f0"
        shape = (
            f'<rect x="{x - 18}" y="{y - 18}" width="36" height="36" fill="{fill}"/>'
            if settings.genders[index] == "M"
            else f'<circle cx="{x}" cy="{y}" r="18" fill="{fill}"/>'
        )
        label = f"{sample} ({annotation})" if annotation else sample
        nodes.append(shape + f'<text x="{x}" y="{y + 38}">{escape(label)}</text>')
    return (
        f'<svg viewBox="0 0 {width} 300" role="img" aria-label="Family tree">'
        '<g stroke="#334155" fill="#e2e8f0" stroke-width="2">'
        + "".join(links + nodes)
        + (
            "</g><style>text{stroke:none;fill:#0f172a;text-anchor:middle;"
            "font:13px system-ui}</style></svg>"
        )
    )
