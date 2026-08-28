"""Load, validate, and derive Hopla settings."""

from __future__ import annotations

import json
import re
import shutil
from pathlib import Path
from typing import Any, Literal

import yaml
from jsonschema import Draft7Validator
from pydantic import BaseModel, ConfigDict, Field, model_validator

Gender = Literal["M", "F"] | None


class Settings(BaseModel):
    """Model all supported analysis settings with strict unknown-key rejection."""

    model_config = ConfigDict(extra="forbid")

    sample_ids: list[str] = Field(min_length=1)
    father_ids: list[str | None] = Field(default_factory=list)
    mother_ids: list[str | None] = Field(default_factory=list)
    genders: list[Gender] = Field(default_factory=list)
    run_merlin: bool = True
    dp_hard_limit_ids: list[str] = Field(default_factory=list)
    dp_hard_limit: float = Field(default=10, ge=0)
    af_hard_limit_ids: list[str] = Field(default_factory=list)
    af_hard_limit: float = Field(default=0, ge=0, lt=1)
    dp_soft_limit_ids: list[str] = Field(default_factory=list)
    dp_soft_limit: float = Field(default=10, ge=0)
    keep_informative_ids: list[str] = Field(default_factory=list, max_length=2)
    keep_hetero_ids: list[str] = Field(default_factory=list)
    regions: list[str] = Field(default_factory=list)
    reference_ids: list[str] = Field(default_factory=list)
    carrier_ids: list[str] = Field(default_factory=list)
    affected_ids: list[str] = Field(default_factory=list)
    nonaffected_ids: list[str] = Field(default_factory=list)
    info: list[str] = Field(default_factory=list)
    baf_ids: list[str] = Field(default_factory=list)
    merlin_model: Literal["sample", "best"] = "best"
    min_seg_var: float = Field(default=5, ge=0)
    min_seg_var_x: float = Field(default=15, ge=0)
    window_size_voting: float = Field(default=10_000_000, ge=0)
    window_size_voting_x: float | None = Field(default=None, ge=0)
    keep_chromosomes_only: bool = True
    keep_regions_only: bool = False
    concordance_table: bool = True
    fam_id: str = Field(default="hopla", min_length=1)
    x_cutoff: float = 1.5
    y_cutoff: float = 0.6
    window_size: int = Field(default=1_000_000, gt=0)
    regions_flanking_size: int = Field(default=2_000_000, ge=0)
    limit_baf_to_p: bool = False
    limit_pm_to_p: bool = False
    value_of_p: float = Field(default=0.25, gt=0, le=1)
    color_palette: str = "Paired"
    dot_factor: float = Field(default=2, gt=0)
    self_contained: bool = False
    cairo: bool = False

    @model_validator(mode="after")
    def validate_family(self) -> Settings:
        """Validate parallel pedigree arrays, references, and regions."""
        size = len(self.sample_ids)
        for name in ("father_ids", "mother_ids", "genders"):
            values = getattr(self, name)
            if not values:
                setattr(self, name, [None] * size)
            elif len(values) != size:
                raise ValueError(f"{name} must have the same length as sample_ids")
        if size > 1 and not any(self.father_ids) and not any(self.mother_ids):
            raise ValueError("multiple samples require father_ids and/or mother_ids")
        referenced = (
            self.dp_hard_limit_ids
            + self.af_hard_limit_ids
            + self.dp_soft_limit_ids
            + self.keep_informative_ids
            + self.keep_hetero_ids
            + self.reference_ids
            + self.carrier_ids
            + self.affected_ids
            + self.nonaffected_ids
            + self.baf_ids
            + [item for item in self.father_ids + self.mother_ids if item is not None]
        )
        unknown = sorted(set(referenced) - set(self.sample_ids))
        if unknown:
            raise ValueError(f"sample references not found in sample_ids: {', '.join(unknown)}")
        if len(self.keep_informative_ids) not in (0, 2):
            raise ValueError("keep_informative_ids must contain zero or two samples")
        for region in self.regions:
            if re.fullmatch(r"chr[^:]+:[0-9]+-[0-9]+", region) is None:
                raise ValueError(f"invalid region: {region}")
        self.window_size_voting_x = self.window_size_voting_x or self.window_size_voting
        self.fam_id = re.sub(r"[^\w]", ".", self.fam_id)
        return self

    @property
    def real_samples(self) -> tuple[str, ...]:
        """Return samples backed by VCF columns rather than pedigree ghosts."""
        return tuple(
            sample for sample in self.sample_ids if re.fullmatch(r"U[0-9]+", sample, re.I) is None
        )

    def derive_filter_ids(self) -> Settings:
        """Fill filter sample lists using the original pedigree-derived defaults."""
        parents = {item for item in self.father_ids + self.mother_ids if item in self.real_samples}
        terminal = [sample for sample in self.real_samples if sample not in parents]
        if len(self.real_samples) == 1:
            parents = set(self.real_samples)
            terminal = list(self.real_samples)
        self.dp_hard_limit_ids = self.dp_hard_limit_ids or sorted(parents)
        self.af_hard_limit_ids = self.af_hard_limit_ids or sorted(parents)
        self.dp_soft_limit_ids = self.dp_soft_limit_ids or terminal
        if (
            len(self.real_samples) == 1
            or shutil.which("merlin") is None
            or shutil.which("minx") is None
        ):
            self.run_merlin = False
        return self


def schema_path() -> Path:
    """Return the package-local JSON schema shipped with Hopla."""
    path = Path(__file__).parent / "schema" / "hopla.schema.json"
    if not path.is_file():
        raise FileNotFoundError(f"Could not locate hopla.schema.json at {path}")
    return path


def load_settings(path: Path) -> Settings:
    """Read and validate a YAML or JSON settings mapping."""
    if path.suffix.lower() not in {".yaml", ".yml", ".json"}:
        raise ValueError("Settings file must use a .yaml, .yml, or .json extension.")
    raw: Any
    with path.open(encoding="utf-8") as handle:
        raw = json.load(handle) if path.suffix.lower() == ".json" else yaml.safe_load(handle)
    if not isinstance(raw, dict):
        raise ValueError("Settings must contain a mapping at the document root.")
    schema = json.loads(schema_path().read_text(encoding="utf-8"))
    errors = sorted(Draft7Validator(schema).iter_errors(raw), key=lambda error: list(error.path))
    if errors:
        raise ValueError(
            "Settings validation failed:\n" + "\n".join(error.message for error in errors)
        )
    return Settings.model_validate(raw).derive_filter_ids()
