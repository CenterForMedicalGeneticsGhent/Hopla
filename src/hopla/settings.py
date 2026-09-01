"""Load, validate, and derive Hopla settings."""

from __future__ import annotations

import json
import logging
import re
import shutil
from pathlib import Path
from typing import Any, Literal

import yaml
from jsonschema import Draft7Validator
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

Sex = Literal["M", "F"] | None
CLI_ONLY_KEYS = frozenset({"vcf_file", "out_dir", "cytoband_file"})
LEGACY_FAMILY_KEYS = frozenset(
    {"sample_ids", "father_ids", "mother_ids", "sexes", "genders", "fam_id"}
)
_REGION_SEPARATORS = re.compile(r"[\s,\u00a0\u202f\uff0c\u066c]+")


def sanitize_region(region: str) -> str:
    """Normalize a copy-pasted interval to schema form ``chrNAME:start-end``.

    Strips whitespace, thousand separators, a missing ``chr`` prefix, and
    mixed-case ``chr`` / ``X`` / ``Y``. Strings that are not an interval
    (no ``:`` after cleaning) are returned unchanged so later validation
    can reject them.
    """
    original = str(region)
    text = _REGION_SEPARATORS.sub("", original)
    if ":" not in text:
        return original
    chrom, interval = text.split(":", 1)
    name = chrom[3:] if chrom.lower().startswith("chr") else chrom
    if name.upper() in {"X", "Y"}:
        name = name.upper()
    return f"chr{name}:{interval}"


class FamilyMember(BaseModel):
    """One pedigree member."""

    model_config = ConfigDict(extra="forbid")

    id: str = Field(min_length=1)
    father: str | None = None
    mother: str | None = None
    sex: Sex = None


class Family(BaseModel):
    """Named family and its members."""

    model_config = ConfigDict(extra="forbid")

    id: str = Field(default="hopla", min_length=1)
    members: list[FamilyMember] = Field(min_length=1)

    @model_validator(mode="after")
    def validate_members(self) -> Family:
        """Reject duplicate IDs, dangling parents, and unrelated member lists."""
        member_ids = [member.id for member in self.members]
        duplicates = sorted(
            sample for sample in set(member_ids) if member_ids.count(sample) > 1
        )
        if duplicates:
            raise ValueError(f"family member IDs must be unique: {', '.join(duplicates)}")
        parents = [
            parent
            for member in self.members
            for parent in (member.father, member.mother)
            if parent is not None
        ]
        unknown = sorted(set(parents) - set(member_ids))
        if unknown:
            raise ValueError(f"sample references not found in family members: {', '.join(unknown)}")
        if len(self.members) > 1 and not parents:
            raise ValueError("multiple family members require a father and/or mother")
        return self

    @property
    def member_ids(self) -> tuple[str, ...]:
        """Return member IDs in declaration order."""
        return tuple(member.id for member in self.members)

    def member(self, sample_id: str) -> FamilyMember:
        """Return the member with this sample ID."""
        for item in self.members:
            if item.id == sample_id:
                return item
        raise KeyError(sample_id)

class Settings(BaseModel):
    """Model all supported analysis settings."""

    model_config = ConfigDict(extra="forbid")

    family: Family
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
    info: str = ""
    baf_ids: list[str] = Field(default_factory=list)
    merlin_model: Literal["sample", "best"] = "best"
    min_seg_var: float = Field(default=5, ge=0)
    min_seg_var_x: float = Field(default=15, ge=0)
    window_size_voting: float = Field(default=10_000_000, ge=0)
    window_size_voting_x: float | None = Field(default=None, ge=0)
    keep_chromosomes_only: bool = True
    keep_regions_only: bool = False
    concordance_table: bool = True
    x_cutoff: float = 1.5
    y_cutoff: float = 0.6
    window_size: int = Field(default=1_000_000, gt=0)
    regions_flanking_size: int = Field(default=2_000_000, ge=0)
    limit_baf_to_p: bool = False
    limit_pm_to_p: bool = False
    value_of_p: float = Field(default=0.25, gt=0, le=1)
    dot_factor: float = Field(default=2, gt=0)

    @field_validator("regions", mode="before")
    @classmethod
    def _sanitize_regions(cls, value: object) -> object:
        """Normalize copy-pasted region strings before type checks."""
        if not isinstance(value, list):
            return value
        return [
            sanitize_region(item) if isinstance(item, str) else item for item in value
        ]

    @model_validator(mode="after")
    def validate_family(self) -> Settings:
        """Validate top-level sample references and analysis regions."""
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
        )
        unknown = sorted(set(referenced) - set(self.family.member_ids))
        if unknown:
            raise ValueError(f"sample references not found in family members: {', '.join(unknown)}")
        if len(self.keep_informative_ids) not in (0, 2):
            raise ValueError("keep_informative_ids must contain zero or two samples")
        for region in self.regions:
            if re.fullmatch(r"chr[^:]+:[0-9]+-[0-9]+", region) is None:
                raise ValueError(f"invalid region: {region}")
        self.window_size_voting_x = self.window_size_voting_x or self.window_size_voting
        self.family.id = re.sub(r"[^\w]", ".", self.family.id)
        return self

    @property
    def real_samples(self) -> tuple[str, ...]:
        """Return samples backed by VCF columns rather than pedigree ghosts."""
        return tuple(
            sample
            for sample in self.family.member_ids
            if re.fullmatch(r"U[0-9]+", sample, re.I) is None
        )

    def derive_filter_ids(self) -> Settings:
        """Fill filter sample lists using the original pedigree-derived defaults."""
        parents = {
            parent
            for member in self.family.members
            for parent in (member.father, member.mother)
            if parent in self.real_samples
        }
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


def schema_properties() -> dict[str, Any]:
    """Return the packaged schema property map."""
    schema = json.loads(schema_path().read_text(encoding="utf-8"))
    properties: dict[str, Any] = schema["properties"]
    return properties


def _aligned_column(name: str, values: object, size: int) -> list[Any]:
    if values in (None, []):
        return [None] * size
    if not isinstance(values, list) or len(values) != size:
        raise ValueError(f"{name} must have the same length as sample_ids")
    return values


def family_from_parallel_arrays(
    sample_ids: list[Any],
    *,
    father_ids: object = None,
    mother_ids: object = None,
    sexes: object = None,
    fam_id: object = None,
) -> dict[str, Any]:
    """Zip historical parallel pedigree arrays into a family object."""
    size = len(sample_ids)
    fathers = _aligned_column("father_ids", father_ids, size)
    mothers = _aligned_column("mother_ids", mother_ids, size)
    sexes_column = _aligned_column("sexes", sexes, size)
    family: dict[str, Any] = {
        "members": [
            {
                "id": sample_id,
                "father": fathers[index],
                "mother": mothers[index],
                "sex": sexes_column[index],
            }
            for index, sample_id in enumerate(sample_ids)
        ]
    }
    if fam_id is not None:
        family["id"] = fam_id
    return family


def prepare_settings_mapping(raw: dict[str, Any]) -> tuple[dict[str, Any], list[str]]:
    """Remap historical names, coerce `info`, sanitize `regions`, and drop unsupported keys."""
    prepared = dict(raw)
    for key in CLI_ONLY_KEYS:
        prepared.pop(key, None)
    ignored: list[str] = []
    if "family" in prepared:
        conflicting = sorted(LEGACY_FAMILY_KEYS.intersection(prepared))
        ignored.extend(conflicting)
        for key in conflicting:
            prepared.pop(key)
    elif isinstance(prepared.get("sample_ids"), list):
        sexes = prepared.get("sexes")
        if sexes is None:
            sexes = prepared.get("genders")
        prepared["family"] = family_from_parallel_arrays(
            prepared["sample_ids"],
            father_ids=prepared.get("father_ids"),
            mother_ids=prepared.get("mother_ids"),
            sexes=sexes,
            fam_id=prepared.get("fam_id"),
        )
        for key in LEGACY_FAMILY_KEYS:
            prepared.pop(key, None)
    if isinstance(prepared.get("info"), list):
        prepared["info"] = "\n".join(str(line) for line in prepared["info"])
    regions = prepared.get("regions")
    if isinstance(regions, list):
        prepared["regions"] = [
            sanitize_region(item) if isinstance(item, str) else item for item in regions
        ]
    allowed = set(schema_properties())
    ignored.extend(key for key in prepared if key not in allowed)
    ignored = sorted(set(ignored))
    if ignored:
        logging.warning("Ignoring unsupported setting(s): %s", ", ".join(ignored))
    return {key: value for key, value in prepared.items() if key in allowed}, ignored


def load_settings(path: Path) -> Settings:
    """Read and validate a YAML or JSON settings mapping."""
    if path.suffix.lower() not in {".yaml", ".yml", ".json"}:
        raise ValueError("Settings file must use a .yaml, .yml, or .json extension.")
    raw: Any
    with path.open(encoding="utf-8") as handle:
        raw = json.load(handle) if path.suffix.lower() == ".json" else yaml.safe_load(handle)
    return validate_settings(raw)


def validate_settings(raw: object) -> Settings:
    """Validate an in-memory settings mapping against the packaged schema."""
    if not isinstance(raw, dict):
        raise ValueError("Settings must contain a mapping at the document root.")
    prepared, _ignored = prepare_settings_mapping(raw)
    schema = json.loads(schema_path().read_text(encoding="utf-8"))
    errors = sorted(
        Draft7Validator(schema).iter_errors(prepared), key=lambda error: list(error.path)
    )
    if errors:
        raise ValueError(
            "Settings validation failed:\n" + "\n".join(error.message for error in errors)
        )
    return Settings.model_validate(prepared).derive_filter_ids()
