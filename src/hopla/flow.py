"""Compare and transform haplotype flow tables."""

from __future__ import annotations

from pathlib import Path

import polars as pl

FLOW_COLUMNS = ("chr", "pos", "flowA.hexcol", "flowB.hexcol")


def _read_flow(path: Path) -> pl.DataFrame:
    """Read required flow columns and retain the original first-file order."""
    frame = pl.read_csv(path, separator="\t")
    missing = set(FLOW_COLUMNS) - set(frame.columns)
    if missing:
        raise ValueError(f"Flow table is missing: {', '.join(sorted(missing))}")
    return frame


def concordance(
    first_path: Path, second_path: Path, *, relative: bool = False
) -> tuple[float, ...]:
    """Calculate four pairwise strand concordance percentages."""
    first = _read_flow(first_path).with_row_index("_order")
    second = _read_flow(second_path)
    joined = first.join(second, on=["chr", "pos"], how="inner", suffix="_second").sort("_order")
    if joined.is_empty():
        raise ValueError("Flow tables have no shared markers.")

    def compare(left: str, right: str) -> float:
        """Compare two aligned flow columns while ignoring unknown X values."""
        pairs = joined.select(left, right).filter((pl.col(left) != "X") & (pl.col(right) != "X"))
        if pairs.is_empty():
            return float("nan")
        left_values = pairs[left]
        right_values = pairs[right]
        if relative:
            left_values = left_values == left_values[0]
            right_values = right_values == right_values[0]
        mean = (left_values == right_values).mean()
        if not isinstance(mean, (int, float)):
            raise ValueError("Could not calculate flow concordance.")
        return round(float(mean) * 100, 2)

    return (
        compare("flowA.hexcol", "flowA.hexcol_second"),
        compare("flowA.hexcol", "flowB.hexcol_second"),
        compare("flowB.hexcol", "flowA.hexcol_second"),
        compare("flowB.hexcol", "flowB.hexcol_second"),
    )


def transform(first_path: Path, second_path: Path, mode: int, output: Path | None = None) -> Path:
    """Rewrite first-table strand colors as booleans relative to the second table."""
    if mode not in (1, 2):
        raise ValueError("mode must be 1 (matching) or 2 (crossed).")
    first = _read_flow(first_path).with_row_index("_order")
    second = _read_flow(second_path).select(FLOW_COLUMNS)
    joined = first.join(second, on=["chr", "pos"], how="inner", suffix="_second").sort("_order")
    if joined.is_empty():
        raise ValueError("Flow tables have no shared markers.")
    right_a = "flowA.hexcol_second" if mode == 1 else "flowB.hexcol_second"
    right_b = "flowB.hexcol_second" if mode == 1 else "flowA.hexcol_second"
    transformed = joined.with_columns(
        (pl.col("flowA.hexcol") == pl.col(right_a)).alias("flowA.hexcol"),
        (pl.col("flowB.hexcol") == pl.col(right_b)).alias("flowB.hexcol"),
    ).select(first.columns[1:])
    target = output or first_path.with_name(f"{first_path.stem}-relative.txt")
    transformed.write_csv(target, separator="\t")
    return target
