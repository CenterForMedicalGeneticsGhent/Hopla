"""Package-local schema resolution and wheel data checks."""

from __future__ import annotations

import json
import tomllib
from pathlib import Path

from hopla.settings import schema_path

PACKAGE_ROOT = Path(__file__).resolve().parents[1]
LOCAL_SCHEMA = PACKAGE_ROOT / "src" / "hopla" / "schema" / "hopla.schema.json"


def test_schema_path_resolves_to_package_local_file() -> None:
    """Resolve the schema next to the installed package modules only."""
    path = schema_path()
    assert path == LOCAL_SCHEMA.resolve()
    assert path.is_file()
    assert path.name == "hopla.schema.json"
    assert path.parent.name == "schema"
    payload = json.loads(path.read_text(encoding="utf-8"))
    assert payload["title"] == "Hopla settings"
    assert payload["type"] == "object"


def test_pyproject_ships_local_schema() -> None:
    """Wheel packaging must embed the packaged schema path."""
    config = tomllib.loads((PACKAGE_ROOT / "pyproject.toml").read_text(encoding="utf-8"))
    force_include = config["tool"]["hatch"]["build"]["targets"]["wheel"]["force-include"]
    assert force_include == {
        "src/hopla/schema/hopla.schema.json": "hopla/schema/hopla.schema.json",
    }
    assert LOCAL_SCHEMA.is_file()
    serialized = (PACKAGE_ROOT / "pyproject.toml").read_text(encoding="utf-8")
    assert "hopla/schema/hopla.schema.json" in serialized
