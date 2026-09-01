"""Package-local schema resolution and wheel data checks."""

from __future__ import annotations

import json
import tomllib
from pathlib import Path

import pytest

from hopla.settings import sanitize_region, schema_path, validate_settings

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
    assert force_include["src/hopla/schema/hopla.schema.json"] == (
        "hopla/schema/hopla.schema.json"
    )
    assert LOCAL_SCHEMA.is_file()
    assert (PACKAGE_ROOT / "src/hopla/ui/templates/index.html").is_file()
    assert (PACKAGE_ROOT / "src/hopla/ui/static/app.js").is_file()
    serialized = (PACKAGE_ROOT / "pyproject.toml").read_text(encoding="utf-8")
    assert "hopla/schema/hopla.schema.json" in serialized


def test_structured_family_is_independent_of_member_order() -> None:
    """Resolve parent links by member ID rather than parallel-array position."""
    settings = validate_settings(
        {
            "family": {
                "id": "family one",
                "members": [
                    {"id": "CHILD", "father": "FATHER", "mother": "MOTHER"},
                    {"id": "MOTHER", "sex": "F"},
                    {"id": "FATHER", "sex": "M"},
                ],
            },
            "run_merlin": False,
        }
    )
    assert settings.family.member_ids == ("CHILD", "MOTHER", "FATHER")
    assert settings.family.member("CHILD").father == "FATHER"
    assert settings.family.member("CHILD").mother == "MOTHER"
    assert [member.sex for member in settings.family.members] == [None, "F", "M"]
    assert settings.family.id == "family.one"


@pytest.mark.parametrize(
    ("family", "message"),
    [
        ({"members": [{"id": "A"}, {"id": "A"}]}, "must be unique"),
        ({"members": [{"id": "A", "role": "child"}]}, "Additional properties"),
        ({"members": [{"id": "A", "father": "UNKNOWN"}]}, "not found"),
    ],
)
def test_structured_family_rejects_invalid_members(
    family: dict[str, object], message: str
) -> None:
    """Reject duplicate IDs, unknown properties, and dangling parents."""
    with pytest.raises(ValueError, match=message):
        validate_settings({"family": family})


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("17:43,044,295-43,170,327", "chr17:43044295-43170327"),
        ("chr17:43044295-43170327", "chr17:43044295-43170327"),
        ("Chr17: 43,044,295 - 43,170,327", "chr17:43044295-43170327"),
        ("x:100-200", "chrX:100-200"),
        ("chrY:1-2", "chrY:1-2"),
        ("not-a-region", "not-a-region"),
    ],
)
def test_sanitize_region(raw: str, expected: str) -> None:
    """Strip commas, spaces, and a missing chr prefix from copy-pasted intervals."""
    assert sanitize_region(raw) == expected


def test_validate_settings_accepts_copy_pasted_region() -> None:
    """Normalize internet-style intervals before schema validation."""
    settings = validate_settings(
        {
            "family": {"members": [{"id": "A"}]},
            "regions": ["17:43,044,295-43,170,327"],
            "run_merlin": False,
        }
    )
    assert settings.regions == ["chr17:43044295-43170327"]


def test_validate_settings_rejects_invalid_region() -> None:
    """Reject region strings that are not an interval after sanitization."""
    with pytest.raises(ValueError, match="does not match|invalid region"):
        validate_settings(
            {
                "family": {"members": [{"id": "A"}]},
                "regions": ["not-a-region"],
                "run_merlin": False,
            }
        )
