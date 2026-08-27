"""Typed data structures shared by the analysis pipeline."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
import numpy.typing as npt

Int8Array = npt.NDArray[np.int8]
UInt16Array = npt.NDArray[np.uint16]
UInt32Array = npt.NDArray[np.uint32]
UInt8Array = npt.NDArray[np.uint8]
BoolArray = npt.NDArray[np.bool_]
Float32Array = npt.NDArray[np.float32]

CHROMOSOMES = tuple([f"chr{i}" for i in range(1, 23)] + ["chrX"])
CHROMOSOME_CODES = {chrom: index + 1 for index, chrom in enumerate(CHROMOSOMES)}
CHROMOSOME_CODES["chrY"] = 24


@dataclass(slots=True, frozen=True)
class SiteTable:
    """Store immutable variant-level columns once for every sample."""

    chrom: UInt8Array
    pos: UInt32Array
    ref: npt.NDArray[np.str_]
    alt: npt.NDArray[np.str_]

    @property
    def size(self) -> int:
        """Return the number of retained SNV sites."""
        return int(self.pos.size)


@dataclass(slots=True, frozen=True)
class GenotypeMatrix:
    """Store compact sample-by-site genotype and depth matrices."""

    gt: Int8Array
    dp: UInt16Array
    ad_ref: UInt16Array
    ad_alt: UInt16Array
    samples: tuple[str, ...]
    sample_index: dict[str, int]

    def allele_fraction(self) -> Float32Array:
        """Calculate alternate-allele fractions without retaining another matrix."""
        total = self.ad_ref.astype(np.float32) + self.ad_alt
        result = np.full(total.shape, np.nan, dtype=np.float32)
        np.divide(self.ad_alt, total, out=result, where=total > 0)
        return result


@dataclass(slots=True, frozen=True)
class FilteredGenotypes:
    """Reference the source matrices through site and sample-validity masks."""

    site_mask: BoolArray
    gt: Int8Array
    dp: npt.NDArray[np.float32]
    af: Float32Array


@dataclass(slots=True, frozen=True)
class Cytoband:
    """Represent one UCSC chromosome band."""

    chrom: str
    start: int
    end: int
    name: str
    stain: str


@dataclass(slots=True, frozen=True)
class ReportSeries:
    """Represent a portable report series before rendering or export."""

    track_id: str
    sample: str
    chrom: str
    start: npt.NDArray[np.uint32]
    end: npt.NDArray[np.uint32]
    value: npt.NDArray[np.float32]
    filter_level: int
