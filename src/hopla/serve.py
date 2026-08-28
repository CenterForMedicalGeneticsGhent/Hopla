"""Local web server for the Hopla settings editor."""

from __future__ import annotations

import asyncio
import re
import tempfile
import uuid
from collections.abc import Awaitable, Callable
from contextlib import asynccontextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import Any, AsyncIterator

from starlette.applications import Starlette
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import FileResponse, HTMLResponse, JSONResponse, Response
from starlette.routing import Mount, Route
from starlette.staticfiles import StaticFiles
from starlette.templating import Jinja2Templates

from hopla.pipeline import run_analysis
from hopla.settings import Settings
from hopla.ui.form import default_form, form_to_settings, import_config, render_yaml

MAX_REQUEST_BYTES = 1024 * 1024 + 64 * 1024
UI_DIRECTORY = Path(__file__).parent / "ui"
templates = Jinja2Templates(directory=UI_DIRECTORY / "templates")


@dataclass
class AnalysisJob:
    """Track one temporary analysis launched from the editor."""

    identifier: str
    directory: Path
    settings: Settings
    status: str = "awaiting_upload"
    message: str = "Waiting for VCF upload"
    report: Path | None = None
    error: str | None = None


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Add browser security headers to every editor response."""

    async def dispatch(
        self, request: Request, call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        """Apply headers after handling a request."""
        response = await call_next(request)
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; script-src 'self'; style-src 'self'; "
            "img-src 'self' data:; connect-src 'self'; object-src 'none'; "
            "base-uri 'none'; frame-ancestors 'none'; form-action 'self'"
        )
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["X-Frame-Options"] = "DENY"
        return response


async def _json_body(request: Request) -> dict[str, Any]:
    body = await request.body()
    if len(body) > MAX_REQUEST_BYTES:
        raise ValueError("Request is larger than the 1 MB configuration limit.")
    value = await request.json()
    if not isinstance(value, dict):
        raise ValueError("Request body must be a JSON object.")
    return value


async def editor(request: Request) -> HTMLResponse:
    """Render the settings editor."""
    return templates.TemplateResponse(request, "index.html", {"initial_state": default_form()})


async def preview(request: Request) -> JSONResponse:
    """Validate browser state and return its YAML representation."""
    try:
        data = await _json_body(request)
        return JSONResponse({"yaml": render_yaml(data["form"])})
    except (KeyError, TypeError, ValueError) as error:
        return JSONResponse({"error": str(error)}, status_code=422)


async def import_settings(request: Request) -> JSONResponse:
    """Import uploaded configuration text into browser form state."""
    try:
        data = await _json_body(request)
        return JSONResponse({"form": import_config(str(data["name"]), str(data["content"]))})
    except (KeyError, TypeError, ValueError) as error:
        return JSONResponse({"error": str(error)}, status_code=422)


async def download(request: Request) -> Response:
    """Validate browser state and return a YAML attachment."""
    try:
        data = await _json_body(request)
        form = data["form"]
        text = render_yaml(form)
        family = re.sub(r"[^\w.-]", "_", str(form.get("fam_id", "hopla")))
        return Response(
            text,
            media_type="application/yaml",
            headers={"Content-Disposition": f'attachment; filename="{family}.yaml"'},
        )
    except (KeyError, TypeError, ValueError) as error:
        return JSONResponse({"error": str(error)}, status_code=422)


def _job(request: Request) -> AnalysisJob | None:
    identifier = request.path_params["job_id"]
    return request.app.state.analysis_jobs.get(identifier)


async def create_analysis(request: Request) -> JSONResponse:
    """Validate editor state and reserve temporary storage for an analysis."""
    try:
        data = await _json_body(request)
        filename = str(data["vcf_name"])
        lower_name = filename.lower()
        if not lower_name.endswith((".vcf", ".vcf.gz", ".vcf.bgz")):
            raise ValueError("Choose a .vcf, .vcf.gz, or .vcf.bgz file.")
        settings = form_to_settings(data["form"])
        identifier = uuid.uuid4().hex
        directory = request.app.state.analysis_directory / identifier
        directory.mkdir()
        job = AnalysisJob(identifier, directory, settings)
        request.app.state.analysis_jobs[identifier] = job
        return JSONResponse({"id": identifier, "status": job.status}, status_code=201)
    except (KeyError, TypeError, ValueError) as error:
        return JSONResponse({"error": str(error)}, status_code=422)


def _execute_analysis(job: AnalysisJob, vcf_path: Path) -> None:
    job.status = "running"

    def progress(message: str) -> None:
        job.message = message

    try:
        job.report = run_analysis(
            job.settings,
            vcf_path,
            job.directory,
            export_parquet_data=False,
            export_bigwig=False,
            progress=progress,
        )
        job.status = "completed"
        job.message = "Analysis complete"
    except Exception as error:
        job.status = "failed"
        job.message = "Analysis failed"
        job.error = str(error)


async def upload_vcf(request: Request) -> JSONResponse:
    """Stream an uploaded VCF into a job and launch its analysis."""
    job = _job(request)
    if job is None:
        return JSONResponse({"error": "Analysis job not found."}, status_code=404)
    if job.status != "awaiting_upload":
        return JSONResponse({"error": "This analysis already received a VCF."}, status_code=409)
    compressed = request.query_params.get("compressed") == "true"
    vcf_path = job.directory / ("input.vcf.gz" if compressed else "input.vcf")
    size = 0
    try:
        with vcf_path.open("wb") as handle:
            async for chunk in request.stream():
                size += len(chunk)
                handle.write(chunk)
        if size == 0:
            vcf_path.unlink(missing_ok=True)
            raise ValueError("The selected VCF is empty.")
    except (OSError, ValueError) as error:
        job.status = "failed"
        job.message = "VCF upload failed"
        job.error = str(error)
        return JSONResponse({"error": str(error)}, status_code=422)
    task = asyncio.create_task(asyncio.to_thread(_execute_analysis, job, vcf_path))
    request.app.state.analysis_tasks.add(task)
    task.add_done_callback(request.app.state.analysis_tasks.discard)
    return JSONResponse({"id": job.identifier, "status": "running"}, status_code=202)


async def analysis_status(request: Request) -> JSONResponse:
    """Return the current state of a temporary analysis."""
    job = _job(request)
    if job is None:
        return JSONResponse({"error": "Analysis job not found."}, status_code=404)
    result: dict[str, Any] = {
        "id": job.identifier,
        "status": job.status,
        "message": job.message,
    }
    if job.error is not None:
        result["error"] = job.error
    if job.status == "completed":
        result["report_url"] = f"/api/analyses/{job.identifier}/report"
    return JSONResponse(result)


async def analysis_report(request: Request) -> Response:
    """Download a completed analysis report."""
    job = _job(request)
    if job is None:
        return JSONResponse({"error": "Analysis job not found."}, status_code=404)
    if job.status != "completed" or job.report is None or not job.report.is_file():
        return JSONResponse({"error": "The analysis report is not ready."}, status_code=409)
    return FileResponse(
        job.report,
        media_type="text/html",
        filename=job.report.name,
    )


@asynccontextmanager
async def _lifespan(app: Starlette) -> AsyncIterator[None]:
    with tempfile.TemporaryDirectory(prefix="hopla-web-") as temporary:
        app.state.analysis_directory = Path(temporary)
        app.state.analysis_jobs = {}
        app.state.analysis_tasks = set()
        yield
        if app.state.analysis_tasks:
            await asyncio.gather(*app.state.analysis_tasks, return_exceptions=True)


def create_app() -> Starlette:
    """Create the local settings editor and analysis application."""
    app = Starlette(
        lifespan=_lifespan,
        routes=[
            Route("/", editor),
            Route("/api/preview", preview, methods=["POST"]),
            Route("/api/import", import_settings, methods=["POST"]),
            Route("/api/download", download, methods=["POST"]),
            Route("/api/analyses", create_analysis, methods=["POST"]),
            Route("/api/analyses/{job_id:str}/vcf", upload_vcf, methods=["PUT"]),
            Route("/api/analyses/{job_id:str}", analysis_status),
            Route("/api/analyses/{job_id:str}/report", analysis_report),
            Mount("/static", StaticFiles(directory=UI_DIRECTORY / "static"), name="static"),
        ]
    )
    app.add_middleware(SecurityHeadersMiddleware)
    return app

