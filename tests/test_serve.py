"""Settings editor model and HTTP endpoint tests."""

from __future__ import annotations

from pathlib import Path

import yaml
from starlette.testclient import TestClient

from hopla.serve import create_app
from hopla.settings import validate_settings
from hopla.ui.form import default_form, import_config, render_yaml, settings_to_form


def _single_sample_form() -> dict[str, object]:
    state = default_form()
    state["members"]["father"]["sample_id"] = "FATHER"
    return state


def test_editor_and_validated_download() -> None:
    """Render the editor and download schema-valid YAML."""
    with TestClient(create_app()) as client:
        page = client.get("/")
        assert page.status_code == 200
        assert "Hopla settings editor" in page.text
        assert page.headers["x-frame-options"] == "DENY"

        preview = client.post("/api/preview", json={"form": _single_sample_form()})
        assert preview.status_code == 200
        settings = yaml.safe_load(preview.json()["yaml"])
        validate_settings(settings)
        assert settings["sample_ids"] == ["FATHER"]
        assert "vcf_file" not in settings
        assert "cytoband_file" not in settings

        download = client.post("/api/download", json={"form": _single_sample_form()})
        assert download.status_code == 200
        assert 'filename="famID.yaml"' in download.headers["content-disposition"]


def test_add_sibling_state_and_validation_error() -> None:
    """Accept repeatable member state and surface invalid values."""
    state = _single_sample_form()
    sibling = {
        "role": "sibling",
        "sample_id": "CHILD",
        "sex": "F",
        "disease_status": "affected",
        "hard_dp": False,
        "hard_af": False,
        "soft_dp": True,
        "informative": False,
        "hetero": False,
        "baf": True,
    }
    state["siblings"].append(sibling)
    settings = yaml.safe_load(render_yaml(state))
    assert settings["father_ids"] == [None, "FATHER"]
    assert settings["affected_ids"] == ["CHILD"]
    assert settings["baf_ids"] == ["CHILD"]
    assert settings["sexes"] == ["M", "F"]
    assert "self_contained" not in settings
    assert "color_palette" not in settings
    assert "cairo" not in settings

    state["af_hard_limit"] = 2
    with TestClient(create_app()) as client:
        response = client.post("/api/preview", json={"form": state})
    assert response.status_code == 422
    assert "maximum of 1" in response.json()["error"]


def test_import_yaml_and_reconstruct_pedigree() -> None:
    """Reconstruct the youngest family from normal settings YAML."""
    path = Path(__file__).parents[1] / "example" / "settings.yaml"
    state, ignored = import_config(path.name, path.read_text(encoding="utf-8"))
    assert ignored == []
    assert state["members"]["father"]["sample_id"] == "DNA052960"
    assert state["members"]["mother"]["sample_id"] == "DNA052959"
    assert state["members"]["maternal_grandfather"]["sample_id"] == "U1"
    assert state["members"]["maternal_grandmother"]["sample_id"] == "DNA052961"
    assert [member["sample_id"] for member in state["embryos"]] == ["DNA052963", "DNA052966"]
    assert state["siblings"] == []
    assert "Breast cancer" in state["info"]
    assert "disease" not in state
    assert "inheritance" not in state
    generated = yaml.safe_load(render_yaml(state))
    validate_settings(generated)
    assert isinstance(generated["info"], str)


def test_import_legacy_and_ignore_unknown_setting() -> None:
    """Import legacy text and ignore unknown schema properties."""
    legacy = "\n".join(
        [
            "sample.ids=FATHER,MOTHER,EMBRYO",
            "father.ids=NA,NA,FATHER",
            "mother.ids=NA,NA,MOTHER",
            "genders=M,F,NA",
            "dp.soft.limit.ids=EMBRYO",
            "affected.ids=MOTHER",
        ]
    )
    with TestClient(create_app()) as client:
        imported = client.post(
            "/api/import", json={"name": "family.txt", "content": legacy}
        )
        assert imported.status_code == 200
        payload = imported.json()
        state = payload["form"]
        assert state["members"]["father"]["sample_id"] == "FATHER"
        assert state["members"]["father"]["sex"] == "M"
        assert [member["sample_id"] for member in state["embryos"]] == ["EMBRYO"]
        assert payload["warnings"] == []

        ignored = client.post(
            "/api/import",
            json={"name": "bad.yaml", "content": "sample_ids: [A]\nunknown: true\n"},
        )
        assert ignored.status_code == 200
        assert ignored.json()["warnings"] == ["unknown"]
        generated = yaml.safe_load(render_yaml(ignored.json()["form"]))
        assert generated["sample_ids"] == ["A"]
        assert "unknown" not in generated

        rejected = client.post(
            "/api/import",
            json={"name": "bad.yaml", "content": "sample_ids: 1\n"},
        )
        assert rejected.status_code == 422


def test_settings_to_form_preserves_unedited_schema_fields() -> None:
    """Carry settings without form controls through an import/export cycle."""
    state = settings_to_form(
        {
            "sample_ids": ["A"],
            "run_merlin": False,
            "dot_factor": 3,
        }
    )
    generated = yaml.safe_load(render_yaml(state))
    assert generated["run_merlin"] is False
    assert generated["dot_factor"] == 3
    assert "self_contained" not in generated
    assert "color_palette" not in generated
    assert "cairo" not in generated

