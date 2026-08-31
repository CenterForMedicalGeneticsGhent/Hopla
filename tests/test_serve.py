"""Settings editor model and HTTP endpoint tests."""

from __future__ import annotations

import time
from pathlib import Path
from typing import Any

import pytest
import yaml
from starlette.testclient import TestClient

from hopla.pipeline import ProgressCallback
from hopla.serve import create_app
from hopla.settings import Settings, validate_settings
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
        assert settings["family"]["members"] == [
            {"id": "FATHER", "father": None, "mother": None, "sex": "M"}
        ]
        assert "vcf_file" not in settings
        assert "cytoband_file" not in settings

        download = client.post("/api/download", json={"form": _single_sample_form()})
        assert download.status_code == 200
        assert 'filename="famID.yaml"' in download.headers["content-disposition"]


def test_no_analysis_hides_tab_and_endpoints() -> None:
    """Serve settings only when the analysis runner is disabled."""
    with TestClient(create_app(analysis=False)) as client:
        page = client.get("/")
        assert page.status_code == 200
        assert 'data-tab="analysis"' not in page.text
        assert 'id="vcf-upload"' not in page.text
        assert client.post("/api/preview", json={"form": _single_sample_form()}).status_code == 200

        created = client.post(
            "/api/analyses",
            json={"form": _single_sample_form(), "vcf_name": "family.vcf"},
        )
        assert created.status_code == 404
        assert client.get("/api/analyses/missing").status_code == 404


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
    assert settings["family"]["members"][1]["father"] == "FATHER"
    assert settings["affected_ids"] == ["CHILD"]
    assert settings["baf_ids"] == ["CHILD"]
    assert [member["sex"] for member in settings["family"]["members"]] == ["M", "F"]
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
        assert generated["family"]["members"][0]["id"] == "A"
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
            "family": {"members": [{"id": "A"}]},
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


def _wait_for_status(
    client: TestClient, identifier: str, expected: str
) -> dict[str, Any]:
    for _ in range(100):
        result = client.get(f"/api/analyses/{identifier}").json()
        if result["status"] == expected:
            return result
        time.sleep(0.01)
    raise AssertionError(f"Analysis did not reach {expected}")


def test_stream_vcf_run_and_download_report(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Stream a VCF, run with editor settings, and download its report."""

    def fake_run(
        settings: Settings,
        vcf_path: Path,
        out_dir: Path,
        *,
        cytoband_path: Path | None = None,
        export_parquet_data: bool = False,
        export_bigwig: bool = False,
        progress: ProgressCallback | None = None,
    ) -> Path:
        del cytoband_path
        assert settings.family.member_ids == ("FATHER",)
        assert vcf_path.read_bytes() == b"VCF data"
        assert export_parquet_data is False
        assert export_bigwig is False
        assert progress is not None
        progress("Computing analyses")
        report = out_dir / f"{settings.family.id}-output.html"
        report.write_text("<html>report</html>", encoding="utf-8")
        return report

    monkeypatch.setattr("hopla.serve.run_analysis", fake_run)
    with TestClient(create_app()) as client:
        created = client.post(
            "/api/analyses",
            json={"form": _single_sample_form(), "vcf_name": "family.vcf"},
        )
        assert created.status_code == 201
        identifier = created.json()["id"]
        uploaded = client.put(
            f"/api/analyses/{identifier}/vcf?compressed=false",
            content=b"VCF data",
        )
        assert uploaded.status_code == 202
        status = _wait_for_status(client, identifier, "completed")
        assert status["message"] == "Analysis complete"
        assert status["report_url"].endswith(f"/{identifier}/report")
        messages = [entry["message"] for entry in status["log"]]
        assert messages == [
            "Received 0.0 MB VCF",
            "Computing analyses",
            "Analysis complete",
        ]
        assert all(entry["seconds"] >= 0 for entry in status["log"])

        report = client.get(status["report_url"])
        assert report.status_code == 200
        assert report.text == "<html>report</html>"
        assert 'filename="famID-output.html"' in report.headers["content-disposition"]


def test_analysis_rejects_invalid_input_and_empty_vcf() -> None:
    """Reject invalid configuration, extensions, and empty uploads."""
    invalid = _single_sample_form()
    invalid["af_hard_limit"] = 2
    with TestClient(create_app()) as client:
        bad_settings = client.post(
            "/api/analyses",
            json={"form": invalid, "vcf_name": "family.vcf"},
        )
        assert bad_settings.status_code == 422
        assert "maximum of 1" in bad_settings.json()["error"]

        bad_extension = client.post(
            "/api/analyses",
            json={"form": _single_sample_form(), "vcf_name": "family.txt"},
        )
        assert bad_extension.status_code == 422

        created = client.post(
            "/api/analyses",
            json={"form": _single_sample_form(), "vcf_name": "family.vcf.gz"},
        )
        identifier = created.json()["id"]
        empty = client.put(f"/api/analyses/{identifier}/vcf?compressed=true", content=b"")
        assert empty.status_code == 422
        status = client.get(f"/api/analyses/{identifier}").json()
        assert status["status"] == "failed"
        assert status["error"] == "The selected VCF is empty."
        assert status["log"][-1]["message"] == (
            "VCF upload failed: The selected VCF is empty."
        )


def test_analysis_surfaces_pipeline_failure(monkeypatch: pytest.MonkeyPatch) -> None:
    """Expose a pipeline failure through job status without a report."""

    def fail_run(
        settings: Settings,
        vcf_path: Path,
        out_dir: Path,
        *,
        cytoband_path: Path | None = None,
        export_parquet_data: bool = False,
        export_bigwig: bool = False,
        progress: ProgressCallback | None = None,
    ) -> Path:
        del (
            settings,
            vcf_path,
            out_dir,
            cytoband_path,
            export_parquet_data,
            export_bigwig,
            progress,
        )
        raise ValueError("VCF does not contain sample FATHER")

    monkeypatch.setattr("hopla.serve.run_analysis", fail_run)
    with TestClient(create_app()) as client:
        created = client.post(
            "/api/analyses",
            json={"form": _single_sample_form(), "vcf_name": "family.vcf"},
        )
        identifier = created.json()["id"]
        client.put(f"/api/analyses/{identifier}/vcf", content=b"bad data")
        status = _wait_for_status(client, identifier, "failed")
        assert status["error"] == "VCF does not contain sample FATHER"
        assert status["log"][-1]["message"] == (
            "Analysis failed: VCF does not contain sample FATHER"
        )
        report = client.get(f"/api/analyses/{identifier}/report")
        assert report.status_code == 409

