"""Convert historical key-value settings files to schema-compatible YAML."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import yaml
from jsonschema import Draft7Validator

from hopla.settings import schema_path


def _parse_legacy(path: Path) -> dict[str, str | list[str]]:
    """Parse legacy assignments and the multiline information block."""
    result: dict[str, str | list[str]] = {}
    info: list[str] = []
    in_info = False
    for original in path.read_text(encoding="utf-8").splitlines():
        line = original.replace("\t", "    ") if in_info else original.replace("'", "").replace('"', "")
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
        result["info"] = info
    return result


def _coerce(value: str | list[str], specification: dict[str, Any]) -> Any:
    """Convert one legacy string according to its JSON-schema property."""
    if isinstance(value, list):
        return value
    kinds = specification.get("type", [])
    kinds = [kinds] if isinstance(kinds, str) else kinds
    if "array" in kinds:
        allows_null = "null" in specification.get("items", {}).get("type", [])
        return [None if token.strip() in {"", "NA"} and allows_null else token.strip()
                for token in value.split(",")]
    if "boolean" in kinds:
        normalized = value.upper()
        if normalized not in {"TRUE", "FALSE", "T", "F"}:
            raise ValueError(f"Could not parse boolean: {value}")
        return normalized in {"TRUE", "T"}
    if "number" in kinds:
        return float(value)
    return value


def convert_settings(legacy: Path, output: Path | None = None) -> Path:
    """Convert legacy settings to validated, ordered YAML."""
    schema = json.loads(schema_path().read_text(encoding="utf-8"))
    properties: dict[str, dict[str, Any]] = schema["properties"]
    raw = _parse_legacy(legacy)
    for cli_key in ("vcf_file", "out_dir", "cytoband_file"):
        raw.pop(cli_key, None)
    unknown = set(raw) - set(properties)
    if unknown:
        raise ValueError(f"Unknown legacy setting(s): {', '.join(sorted(unknown))}")
    converted = {key: _coerce(raw[key], properties[key]) for key in properties if key in raw}
    errors = list(Draft7Validator(schema).iter_errors(converted))
    if errors:
        raise ValueError("Converted settings failed validation:\n" + "\n".join(e.message for e in errors))
    target = output or legacy.with_suffix(".yaml")
    target.write_text(yaml.safe_dump(converted, sort_keys=False), encoding="utf-8")
    return target
