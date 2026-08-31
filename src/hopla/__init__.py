"""Hopla genomic family analysis."""

from importlib.metadata import PackageNotFoundError, version

try:
    __version__ = version("hopla")
except PackageNotFoundError:
    __version__ = "4.0.0"

__all__ = ["__version__"]
