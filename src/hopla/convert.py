"""Convert historical key-value settings files to schema-compatible YAML."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import yaml
from jsonschema import Draft7Validator

from hopla.settings import prepare_settings_mapping, schema_path, schema_properties


def parse_legacy_text(text: str) -> dict[str, str | list[str]]:
    """Parse legacy assignments and the multiline information block."""
    result: dict[str, str | list[str]] = {}
    info: list[str] = []
    in_info = False
    for original in text.splitlines():
        line = (
            original.replace("\t", "    ")
            if in_info
            else original.replace("'", "").replace('"', "")
        )
        stripped = line.strip()
        if stripped == "start.info":
            if in_info:
                raise ValueError("nested start.info")
            in_info = True
            continue
        if stripped == "end.info":
            if not in_info:
                raise ValueError("end.info without start.info")
            in_info = False
            continue
        if in_info:
            info.append(line)
            continue
        line = stripped.split("#", 1)[0].strip()
        if not line:
            continue
        if "=" not in line:
            raise ValueError(f"Legacy settings line is not key=value: {line}")
        key, value = (part.strip() for part in line.split("=", 1))
        if value:
            result[key.replace(".", "_").lower()] = value
    if in_info:
        raise ValueError("Legacy settings file is missing end.info.")
    if info:
        result["info"] = "\n".join(info)
    return result


def _parse_legacy(path: Path) -> dict[str, str | list[str]]:
    """Parse a legacy settings file."""
    return parse_legacy_text(path.read_text(encoding="utf-8"))


def _coerce(value: str | list[str], specification: dict[str, Any]) -> Any:
    """Convert one legacy string according to its JSON-schema property."""
    kinds = specification.get("type", [])
    kinds = [kinds] if isinstance(kinds, str) else kinds
    if isinstance(value, list):
        return value
    if "array" in kinds:
        item_specification = specification.get("items", {})
        item_kinds = item_specification.get("type", [])
        item_kinds = [item_kinds] if isinstance(item_kinds, str) else item_kinds
        allows_null = "null" in item_kinds or None in item_specification.get("enum", [])
        return [
            None if token.strip() in {"", "NA"} and allows_null else token.strip()
            for token in value.split(",")
        ]
    if "boolean" in kinds:
        normalized = value.upper()
        if normalized not in {"TRUE", "FALSE", "T", "F"}:
            raise ValueError(f"Could not parse boolean: {value}")
        return normalized in {"TRUE", "T"}
    if "number" in kinds:
        return float(value)
    return value


def _convert_mapping(raw: dict[str, str | list[str]]) -> dict[str, Any]:
    """Coerce a parsed legacy mapping and drop unsupported keys."""
    schema = json.loads(schema_path().read_text(encoding="utf-8"))
    properties = schema_properties()
    prepared, _ignored = prepare_settings_mapping(raw)
    converted = {
        key: _coerce(prepared[key], properties[key]) for key in properties if key in prepared
    }
    errors = list(Draft7Validator(schema).iter_errors(converted))
    if errors:
        raise ValueError(
            "Converted settings failed validation:\n" + "\n".join(error.message for error in errors)
        )
    return converted


def convert_settings(legacy: Path, output: Path | None = None) -> Path:
    """Convert legacy settings to validated, ordered YAML."""
    converted = _convert_mapping(_parse_legacy(legacy))
    target = output or legacy.with_suffix(".yaml")
    target.write_text(yaml.safe_dump(converted, sort_keys=False), encoding="utf-8")
    return target


def convert_legacy_data(text: str) -> dict[str, Any]:
    """Convert legacy settings text to a validated settings mapping."""
    return _convert_mapping(parse_legacy_text(text))
