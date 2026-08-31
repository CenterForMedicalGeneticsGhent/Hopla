"""Derive pedigree state and render a compact accessible SVG."""

from __future__ import annotations

from html import escape

import numpy as np

from hopla.models import CHROMOSOME_CODES, GenotypeMatrix, SiteTable
from hopla.settings import FamilyMember, Settings, Sex


def predict_sexes(settings: Settings, sites: SiteTable, matrix: GenotypeMatrix) -> list[Sex]:
    """Fill unknown sexes from pedigree roles and chromosome depth ratios."""
    fathers = {member.father for member in settings.family.members if member.father}
    mothers = {member.mother for member in settings.family.members if member.mother}
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
        member = settings.family.member(sample)
        if member.sex is not None:
            continue
        if sample in mothers:
            member.sex = "F"
        elif sample in fathers:
            member.sex = "M"
        else:
            matrix_index = matrix.sample_index[sample]
            x_value, y_value = x_copies[matrix_index], y_copies[matrix_index]
            x_sex: Sex = (
                "M" if x_value < settings.x_cutoff else "F" if np.isfinite(x_value) else None
            )
            y_sex: Sex = (
                "F" if y_value < settings.y_cutoff else "M" if np.isfinite(y_value) else None
            )
            if x_sex is None and y_sex is None:
                raise ValueError(f"Could not predict sex for sample {sample}.")
            member.sex = y_sex if y_sex is not None else x_sex
    unresolved = [
        member.id for member in settings.family.members if member.sex is None
    ]
    if unresolved:
        raise ValueError(f"Sex must be provided for ghost sample(s): {', '.join(unresolved)}")
    return [member.sex for member in settings.family.members]


def add_ghosts(settings: Settings) -> Settings:
    """Add missing single parents as sequential U identifiers."""
    existing = [
        int(sample[1:])
        for sample in settings.family.member_ids
        if sample[:1].upper() == "U" and sample[1:].isdigit()
    ]
    counter = max(existing, default=0)
    for member in list(settings.family.members):
        missing_father = member.father is None
        missing_mother = member.mother is None
        if missing_father == missing_mother:
            continue
        counter += 1
        ghost = f"U{counter}"
        if missing_father:
            member.father = ghost
            sex: Sex = "M"
        else:
            member.mother = ghost
            sex = "F"
        settings.family.add_member(FamilyMember(id=ghost, sex=sex))
    return settings


_SYMBOL = 34.0
_COLUMN = 74.0
_GENERATION = 122.0
_MARGIN = 46.0


def sample_label(settings: Settings, sample: str) -> str:
    """Append the legacy status letter to a sample identifier."""
    for letter, members in (
        ("R", settings.reference_ids),
        ("C", settings.carrier_ids),
        ("A", settings.affected_ids),
        ("N", settings.nonaffected_ids),
    ):
        if sample in members:
            return f"{sample} ({letter})"
    return sample


def _generations(settings: Settings) -> list[int]:
    """Place samples one row below their deepest parent and partners on a shared row."""
    index = {sample: position for position, sample in enumerate(settings.family.member_ids)}
    depth = [0] * len(settings.family.members)
    couples = [
        (index[father], index[mother])
        for father, mother in _sibships(settings)
        if father and mother
    ]
    for _ in range(2 * len(depth) + 2):
        changed = False
        for position, member in enumerate(settings.family.members):
            for parent in (member.father, member.mother):
                if parent in index and depth[position] <= depth[index[parent]]:
                    depth[position] = depth[index[parent]] + 1
                    changed = True
        for first, second in couples:
            shared = max(depth[first], depth[second])
            if depth[first] != shared or depth[second] != shared:
                depth[first] = depth[second] = shared
                changed = True
        if not changed:
            break
    return depth


def _sibships(settings: Settings) -> dict[tuple[str, str], list[str]]:
    """Group samples by the parent pair that produced them."""
    known = set(settings.family.member_ids)
    families: dict[tuple[str, str], list[str]] = {}
    for member in settings.family.members:
        father = member.father
        mother = member.mother
        pair = (father if father in known else "", mother if mother in known else "")
        if any(pair):
            families.setdefault(pair, []).append(member.id)
    return families


def _separate(positions: dict[str, float], members: list[str], column: float) -> None:
    """Push one generation apart so no two symbols overlap, keeping their order."""
    for left, right in zip(members, members[1:], strict=False):
        positions[right] = max(positions[right], positions[left] + column)


def _layout(settings: Settings) -> tuple[dict[str, float], list[int]]:
    """Place every sample on a generation row with children centred under parents."""
    depth = _generations(settings)
    families = _sibships(settings)
    partners = {
        member: other
        for father, mother in families
        if father and mother
        for member, other in ((father, mother), (mother, father))
    }
    # Columns are wide enough that neighbouring labels never touch.
    widest = max(len(sample_label(settings, sample)) for sample in settings.family.member_ids)
    column = max(_COLUMN, 7.4 * widest + 18)
    rows: dict[int, list[str]] = {}
    positions: dict[str, float] = {}
    for generation in sorted(set(depth)):
        members = [
            sample
            for position, sample in enumerate(settings.family.member_ids)
            if depth[position] == generation
        ]
        ordered: list[str] = []
        for sample in members:
            if sample in ordered:
                continue
            ordered.append(sample)
            partner = partners.get(sample)
            if partner in members and partner not in ordered:
                ordered.append(partner)
        rows[generation] = ordered
        for slot, sample in enumerate(ordered):
            positions[sample] = slot * column

    def centre(samples: list[str]) -> float:
        """Return the midpoint of the samples that are already placed."""
        placed = [positions[sample] for sample in samples]
        return (min(placed) + max(placed)) / 2

    index = {sample: position for position, sample in enumerate(settings.family.member_ids)}
    for _ in range(6):
        for (father, mother), children in families.items():
            parents = [parent for parent in (father, mother) if parent]
            shift = centre(parents) - centre(children)
            for child in children:
                positions[child] += shift
            _separate(positions, rows[depth[index[children[0]]]], column)
        for (father, mother), children in families.items():
            parents = [parent for parent in (father, mother) if parent]
            if any(
                settings.family.member(parent).father in index
                or settings.family.member(parent).mother in index
                for parent in parents
            ):
                continue
            shift = centre(children) - centre(parents)
            for parent in parents:
                positions[parent] += shift
            _separate(positions, rows[depth[index[parents[0]]]], column)
    offset = _MARGIN - min(positions.values())
    return {sample: value + offset for sample, value in positions.items()}, depth


def pedigree_svg(settings: Settings) -> str:
    """Render the family as a conventional pedigree chart."""
    positions, depth = _layout(settings)
    families = _sibships(settings)
    index = {sample: position for position, sample in enumerate(settings.family.member_ids)}
    rows = {sample: _MARGIN + depth[index[sample]] * _GENERATION for sample in positions}
    half = _SYMBOL / 2

    lines: list[str] = []
    for (father, mother), children in families.items():
        parents = [parent for parent in (father, mother) if parent]
        parent_y = rows[parents[0]]
        if len(parents) == 2:
            left, right = sorted(positions[parent] for parent in parents)
            lines.append(f'<path d="M{left:.1f} {parent_y:.1f}H{right:.1f}"/>')
            anchor = (left + right) / 2
        else:
            anchor = positions[parents[0]]
            parent_y += half
        sibship_y = rows[children[0]] - _GENERATION / 2 + half
        lines.append(f'<path d="M{anchor:.1f} {parent_y:.1f}V{sibship_y:.1f}"/>')
        first, last = min(positions[child] for child in children), max(
            positions[child] for child in children
        )
        lines.append(f'<path d="M{first:.1f} {sibship_y:.1f}H{last:.1f}"/>')
        lines.extend(
            f'<path d="M{positions[child]:.1f} {sibship_y:.1f}'
            f'V{rows[child] - half:.1f}"/>'
            for child in children
        )

    symbols: list[str] = []
    for sample, x in positions.items():
        y = rows[sample]
        sex = settings.family.member(sample).sex
        affected = sample in settings.affected_ids
        fill = "#334155" if affected else "#ffffff"
        if sex == "M":
            symbols.append(
                f'<rect x="{x - half:.1f}" y="{y - half:.1f}" '
                f'width="{_SYMBOL}" height="{_SYMBOL}" fill="{fill}"/>'
            )
        elif sex == "F":
            symbols.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{half}" fill="{fill}"/>')
        else:
            symbols.append(
                f'<path d="M{x:.1f} {y - half:.1f}L{x + half:.1f} {y:.1f}'
                f'L{x:.1f} {y + half:.1f}L{x - half:.1f} {y:.1f}Z" fill="{fill}"/>'
            )
        if sample in settings.carrier_ids and not affected:
            symbols.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="5" fill="#334155"/>')
        symbols.append(
            f'<text x="{x:.1f}" y="{y + half + 16:.1f}">'
            f"{escape(sample_label(settings, sample))}</text>"
        )

    width = max(positions.values()) + _MARGIN
    height = _MARGIN + max(depth) * _GENERATION + _MARGIN + 20
    return (
        f'<svg class="pedigree-svg" viewBox="0 0 {width:.0f} {height:.0f}" width="{width:.0f}" '
        'role="img" aria-label="Family tree">'
        '<g stroke="#334155" stroke-width="1.6" fill="none">' + "".join(lines) + "</g>"
        '<g stroke="#334155" stroke-width="1.6">' + "".join(symbols) + "</g>"
        # An inline SVG stylesheet is document-wide, so every rule stays class-scoped.
        "<style>.pedigree-svg text{stroke:none;fill:#0f172a;text-anchor:middle;"
        "font:12px system-ui,-apple-system,Segoe UI,Roboto,sans-serif}</style></svg>"
    )
