"""Local web server for the Hopla settings editor."""

from __future__ import annotations

import re
from collections.abc import Awaitable, Callable
from pathlib import Path
from typing import Any

from starlette.applications import Starlette
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import HTMLResponse, JSONResponse, Response
from starlette.routing import Mount, Route
from starlette.staticfiles import StaticFiles
from starlette.templating import Jinja2Templates

from hopla.ui.form import default_form, import_config, render_yaml

MAX_REQUEST_BYTES = 1024 * 1024 + 64 * 1024
UI_DIRECTORY = Path(__file__).parent / "ui"
templates = Jinja2Templates(directory=UI_DIRECTORY / "templates")


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
        form, ignored = import_config(str(data["name"]), str(data["content"]))
        return JSONResponse({"form": form, "warnings": ignored})
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


def create_app() -> Starlette:
    """Create the local settings-editor application."""
    app = Starlette(
        routes=[
            Route("/", editor),
            Route("/api/preview", preview, methods=["POST"]),
            Route("/api/import", import_settings, methods=["POST"]),
            Route("/api/download", download, methods=["POST"]),
            Mount("/static", StaticFiles(directory=UI_DIRECTORY / "static"), name="static"),
        ]
    )
    app.add_middleware(SecurityHeadersMiddleware)
    return app

