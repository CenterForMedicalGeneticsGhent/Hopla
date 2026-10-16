"""Translate between the browser form model and Hopla settings."""

from __future__ import annotations

import json
from typing import Any

import yaml

from hopla.convert import convert_legacy_data
from hopla.settings import prepare_settings_mapping, sanitize_region, validate_settings

PLACEHOLDERS = {
    "father": "U1",
    "mother": "U2",
    "paternal_grandfather": "U3",
    "paternal_grandmother": "U4",
    "maternal_grandfather": "U5",
    "maternal_grandmother": "U6",
}
CONTROLLED_KEYS = {
    "family",
    "dp_hard_limit_ids",
    "af_hard_limit_ids",
    "af_hard_limit",
    "dp_soft_limit_ids",
    "keep_informative_ids",
    "keep_hetero_ids",
    "regions",
    "carrier_ids",
    "affected_ids",
    "nonaffected_ids",
    "info",
    "baf_ids",
    "window_size_voting",
    "keep_chromosomes_only",
    "keep_regions_only",
    "regions_flanking_size",
    "limit_baf_to_p",
    "limit_pm_to_p",
    "value_of_p",
}


def _member(
    role: str,
    sample_id: str,
    sex: str | None,
    settings: dict[str, Any] | None = None,
) -> dict[str, Any]:
    values = settings or {}
    disease = "NA"
    if sample_id in values.get("carrier_ids", []):
        disease = "carrier"
    elif sample_id in values.get("affected_ids", []):
        disease = "affected"
    elif sample_id in values.get("nonaffected_ids", []):
        disease = "nonaffected"
    return {
        "role": role,
        "sample_id": sample_id,
        "sex": sex or "NA",
        "disease_status": disease,
        "hard_dp": sample_id in values.get("dp_hard_limit_ids", []),
        "hard_af": sample_id in values.get("af_hard_limit_ids", []),
        "soft_dp": sample_id in values.get("dp_soft_limit_ids", []),
        "informative": sample_id in values.get("keep_informative_ids", []),
        "hetero": sample_id in values.get("keep_hetero_ids", []),
        "baf": sample_id in values.get("baf_ids", []),
    }


def default_form() -> dict[str, Any]:
    """Return the initial settings-editor state."""
    return {
        "fam_id": "famID",
        "members": {
            role: _member(role, sample_id, "M" if "father" in role else "F")
            for role, sample_id in PLACEHOLDERS.items()
        },
        "siblings": [],
        "embryos": [],
        "af_hard_limit": 0.25,
        "regions": [],
        "info": "",
        "window_size_voting": 10_000_000,
        "keep_chromosomes_only": True,
        "keep_regions_only": False,
        "regions_flanking_size": 2_000_000,
        "limit_baf_to_p": False,
        "limit_pm_to_p": True,
        "value_of_p": 0.15,
        "extras": {},
    }


def _pedigree_mapping(settings: dict[str, Any]) -> dict[str, Any]:
    family_members = settings["family"]["members"]
    members = {
        str(member["id"]): {
            "father": member.get("father"),
            "mother": member.get("mother"),
            "index": index,
        }
        for index, member in enumerate(family_members)
    }
    sample_ids = list(members)

    def depth(sample_id: str, visiting: set[str]) -> int:
        if sample_id in visiting or sample_id not in members:
            return 0
        item = members[sample_id]
        parents = [parent for parent in (item["father"], item["mother"]) if parent]
        return (
            0
            if not parents
            else 1 + max(depth(str(parent), visiting | {sample_id}) for parent in parents)
        )

    couples: dict[tuple[Any, Any], dict[str, Any]] = {}
    for sample_id in sample_ids:
        item = members[sample_id]
        if item["father"] is None and item["mother"] is None:
            continue
        key = (item["father"], item["mother"])
        candidate = couples.setdefault(key, {"children": [], "depth": 0, "index": -1})
        candidate["children"].append(sample_id)
        candidate["depth"] = max(candidate["depth"], depth(sample_id, set()))
        candidate["index"] = max(candidate["index"], item["index"])
    if not couples:
        return {"siblings": sample_ids, "embryos": []}
    (father, mother), selected = max(
        couples.items(), key=lambda item: (item[1]["depth"], item[1]["index"])
    )
    embryo_hints = set(settings.get("dp_soft_limit_ids", []) or settings.get("baf_ids", []))
    embryos = [child for child in selected["children"] if child in embryo_hints]
    if not embryos:
        embryos = list(selected["children"])
    siblings = [child for child in selected["children"] if child not in embryos]
    father_data = members.get(str(father), {})
    mother_data = members.get(str(mother), {})
    return {
        "father": father,
        "mother": mother,
        "paternal_grandfather": father_data.get("father"),
        "paternal_grandmother": father_data.get("mother"),
        "maternal_grandfather": mother_data.get("father"),
        "maternal_grandmother": mother_data.get("mother"),
        "siblings": siblings,
        "embryos": embryos,
    }


def settings_to_form(settings: dict[str, Any]) -> dict[str, Any]:
    """Build browser form state from a validated settings mapping."""
    settings, _ignored = prepare_settings_mapping(settings)
    validate_settings(settings)
    state = default_form()
    mapping = _pedigree_mapping(settings)
    family_members = settings["family"]["members"]
    sex_by_id = {member["id"]: member.get("sex") for member in family_members}
    fixed: dict[str, Any] = {}
    for role, placeholder in PLACEHOLDERS.items():
        sample_id = mapping.get(role) or placeholder
        default_sex = "M" if "father" in role else "F"
        fixed[role] = _member(
            role, str(sample_id), sex_by_id.get(sample_id, default_sex), settings
        )
    state["members"] = fixed
    state["siblings"] = [
        _member("sibling", sample_id, sex_by_id.get(sample_id), settings)
        for sample_id in mapping.get("siblings", [])
    ]
    state["embryos"] = [
        _member("embryo", sample_id, sex_by_id.get(sample_id), settings)
        for sample_id in mapping.get("embryos", [])
    ]
    state["fam_id"] = settings["family"].get("id", "hopla")
    for key in (
        "af_hard_limit",
        "regions",
        "window_size_voting",
        "keep_chromosomes_only",
        "keep_regions_only",
        "regions_flanking_size",
        "limit_baf_to_p",
        "limit_pm_to_p",
        "value_of_p",
        "info",
    ):
        if key in settings:
            state[key] = settings[key]
    state["extras"] = {key: value for key, value in settings.items() if key not in CONTROLLED_KEYS}
    return state


def _active(role: str, member: dict[str, Any]) -> bool:
    return member.get("sample_id") != PLACEHOLDERS.get(role)


def form_to_settings(state: dict[str, Any]) -> dict[str, Any]:
    """Build and validate a settings mapping from browser form state."""
    fixed: dict[str, dict[str, Any]] = state["members"]
    active = {role: _active(role, member) for role, member in fixed.items()}
    selected: list[dict[str, Any]] = []
    for role in (
        "paternal_grandfather",
        "paternal_grandmother",
        "maternal_grandfather",
        "maternal_grandmother",
        "father",
        "mother",
    ):
        if active[role]:
            selected.append(fixed[role])
    selected.extend(state.get("siblings", []))
    selected.extend(state.get("embryos", []))
    if not selected:
        raise ValueError("Add at least one family member or replace a placeholder sample ID.")

    father = fixed["father"]["sample_id"] if active["father"] else None
    mother = fixed["mother"]["sample_id"] if active["mother"] else None
    parent_by_role = {
        "father": (
            fixed["paternal_grandfather"]["sample_id"]
            if active["paternal_grandfather"]
            else None,
            fixed["paternal_grandmother"]["sample_id"]
            if active["paternal_grandmother"]
            else None,
        ),
        "mother": (
            fixed["maternal_grandfather"]["sample_id"]
            if active["maternal_grandfather"]
            else None,
            fixed["maternal_grandmother"]["sample_id"]
            if active["maternal_grandmother"]
            else None,
        ),
    }
    family_members: list[dict[str, Any]] = []
    for member in selected:
        role = member["role"]
        if role in parent_by_role:
            member_father, member_mother = parent_by_role[role]
        elif role in {"sibling", "embryo"}:
            member_father, member_mother = father, mother
        else:
            member_father, member_mother = None, None
        family_members.append(
            {
                "id": member["sample_id"],
                "father": member_father,
                "mother": member_mother,
                "sex": None if member.get("sex") == "NA" else member.get("sex"),
            }
        )

    def ids(flag: str) -> list[str]:
        return [str(member["sample_id"]) for member in selected if member.get(flag, False)]

    disease_lists = {
        name: [
            str(member["sample_id"])
            for member in selected
            if member.get("disease_status") == status
        ]
        for name, status in (
            ("carrier_ids", "carrier"),
            ("affected_ids", "affected"),
            ("nonaffected_ids", "nonaffected"),
        )
    }
    result: dict[str, Any] = dict(state.get("extras", {}))
    result.update(
        {
            "family": {"id": str(state["fam_id"]), "members": family_members},
            "dp_hard_limit_ids": ids("hard_dp"),
            "af_hard_limit_ids": ids("hard_af"),
            "af_hard_limit": float(state["af_hard_limit"]),
            "dp_soft_limit_ids": ids("soft_dp"),
            "keep_informative_ids": ids("informative"),
            "keep_hetero_ids": ids("hetero"),
            "regions": [
                sanitize_region(str(region).strip())
                for region in state.get("regions", [])
                if region
            ],
            **disease_lists,
            "info": str(state.get("info") or ""),
            "baf_ids": ids("baf"),
            "window_size_voting": float(state["window_size_voting"]),
            "keep_chromosomes_only": bool(state["keep_chromosomes_only"]),
            "keep_regions_only": bool(state["keep_regions_only"]),
            "regions_flanking_size": int(state["regions_flanking_size"]),
            "limit_baf_to_p": bool(state["limit_baf_to_p"]),
            "limit_pm_to_p": bool(state["limit_pm_to_p"]),
            "value_of_p": float(state["value_of_p"]),
        }
    )
    if not str(result.get("info") or "").strip():
        result.pop("info", None)
    prepared, _ignored = prepare_settings_mapping(result)
    validate_settings(prepared)
    return prepared


def import_config(name: str, text: str) -> tuple[dict[str, Any], list[str]]:
    """Parse an uploaded legacy, YAML, or JSON configuration."""
    if len(text.encode("utf-8")) > 1024 * 1024:
        raise ValueError("Configuration files must be 1 MB or smaller.")
    suffix = name.lower().rsplit(".", 1)[-1]
    if suffix == "txt":
        settings = convert_legacy_data(text)
    elif suffix == "json":
        settings = json.loads(text)
    elif suffix in {"yaml", "yml"}:
        settings = yaml.safe_load(text)
    else:
        raise ValueError("Choose a .txt, .yaml, .yml, or .json configuration file.")
    if not isinstance(settings, dict):
        raise ValueError("Settings must contain a mapping at the document root.")
    prepared, ignored = prepare_settings_mapping(settings)
    return settings_to_form(prepared), ignored


def render_yaml(state: dict[str, Any]) -> str:
    """Return validated YAML for a browser form state."""
    return yaml.safe_dump(form_to_settings(state), sort_keys=False)

