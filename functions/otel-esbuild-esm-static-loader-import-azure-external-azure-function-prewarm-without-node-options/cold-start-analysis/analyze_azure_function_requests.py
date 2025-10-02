#!/usr/bin/env python3
"""
Analyze Azure Function request datasets (markdown tables) comparing
cases with and without `languageWorker_arguments_node`.

Inputs:
  --no-md   Path to 'no node options' markdown file
  --with-md Path to 'with node options' markdown file

Outputs (optional):
  --out-md   Path to write a README-style markdown summary
  --out-csv  Base path (without suffix) to write CSV summaries per metric
  --plots    Directory to save KDE plots per metric (wall, azure, diff)

Example:
  python analyze_azure_function_requests.py \
    --off-md requests-node-arguments-off.md \
    --on-md requests-node-arguments-on.md \
    --out-md analysis.md \
    --out-csv summary \
    --plots ./plots
"""

import argparse
import io
import os
from dateutil import tz
from typing import Tuple

import pandas as pd
import matplotlib.pyplot as plt

tzinfos = {"BST": tz.gettz("Europe/London")}


def read_md_table(path: str) -> pd.DataFrame:
    """Read a GitHub-style markdown table into a DataFrame."""
    with open(path, "r", encoding="utf-8") as f:
        text = f.read().strip()
    lines = [ln for ln in text.splitlines() if ln.strip().startswith("|")]

    # Drop alignment rows (---, :---:, etc.)
    def is_divider(ln: str) -> bool:
        core = ln.replace("|", "").strip()
        return core != "" and set(core).issubset(set("-: "))

    lines = [ln for ln in lines if not is_divider(ln)]
    # Convert to CSV-like
    cleaned = []
    for ln in lines:
        parts = [p.strip() for p in ln.strip("|").split("|")]
        cleaned.append(",".join(parts))
    csv_text = "\n".join(cleaned)
    df = pd.read_csv(io.StringIO(csv_text))
    # Normalize
    df.columns = [c.strip().lower().replace(" ", "_") for c in df.columns]
    for col in ("wall_duration", "azure_duration", "diff_duration"):
        df[col] = pd.to_numeric(df[col], errors="coerce")
    pd.to_datetime(df["time"].replace('BST', '', regex=True), errors="coerce")
    return df


def summarize(df: pd.DataFrame, value_col: str) -> pd.DataFrame:
    g = df.groupby("group")[value_col]
    out = pd.DataFrame(
        {
            "count": g.count(),
            "mean": g.mean(),
            "std": g.std(ddof=1),
            "min": g.min(),
            "p50": g.median(),
            "p95": g.quantile(0.95),
            "p99": g.quantile(0.99),
            "max": g.max(),
        }
    )
    return out


def kde_plot(df: pd.DataFrame, value_col: str, out_path: str | None):
    plt.figure(figsize=(8, 5))
    for grp, sub in df.groupby("group"):
        sub[value_col].plot(kind="kde", label=grp)
    plt.title(f"Distribution of {value_col.replace('_', ' ').title()}")
    plt.xlabel(value_col.replace("_", " ").title())
    plt.ylabel("Density")
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    if out_path:
        plt.savefig(out_path, dpi=160)
    plt.close()


def to_md_table(df: pd.DataFrame, caption: str) -> str:
    return f"### {caption}\n\n{df.round(3).to_markdown()}\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--off-md", required=True, help="Markdown table for OFF node arguments"
    )
    ap.add_argument(
        "--on-md", required=True, help="Markdown table for ON node arguments"
    )
    ap.add_argument(
        "--out-md", default=None, help="Write README-style markdown summary"
    )
    ap.add_argument(
        "--out-csv", default=None, help="Base path to write CSV summaries per metric"
    )
    ap.add_argument("--plots", default=None, help="Directory to write KDE plots")
    args = ap.parse_args()
    print(f"Arguments: {args}")

    df_off = read_md_table(args.off_md)
    df_on = read_md_table(args.on_md)
    df_off["group"] = "off_node_arguments"
    df_on["group"] = "on_node_arguments"
    df = pd.concat([df_off, df_on], ignore_index=True)

    # Data integrity checks
    df["computed_diff"] = df["wall_duration"] - df["azure_duration"]
    df["diff_error"] = (df["computed_diff"] - df["diff_duration"]).abs()
    max_abs_err = float(df["diff_error"].max())

    # Summaries
    summary_wall = summarize(df, "wall_duration")
    summary_azure = summarize(df, "azure_duration")
    summary_diff = summarize(df, "diff_duration")

    # Print to console
    print("\nDATA INTEGRITY")
    print(f"Rows: no_node={len(df_off)}, with_node={len(df_on)}")
    print(f"Max |(Wall - Azure) - Diff| = {max_abs_err:.9f}")
    print("\nWALL DURATION\n", summary_wall.round(3))
    print("\nAZURE DURATION\n", summary_azure.round(3))
    print("\nDIFF DURATION\n", summary_diff.round(3))

    # Optional CSV outputs
    if args.out_csv:
        summary_wall.round(6).to_csv(f"{args.out_csv}_wall.csv")
        summary_azure.round(6).to_csv(f"{args.out_csv}_azure.csv")
        summary_diff.round(6).to_csv(f"{args.out_csv}_diff.csv")

    # Optional plots
    if args.plots:
        os.makedirs(args.plots, exist_ok=True)
        kde_plot(df, "wall_duration", os.path.join(args.plots, "wall_duration.png"))
        kde_plot(df, "azure_duration", os.path.join(args.plots, "azure_duration.png"))
        kde_plot(df, "diff_duration", os.path.join(args.plots, "diff_duration.png"))

    # Optional README output
    if args.out_md:
        md_parts = [
            "# Azure Function Request Analysis",
            "",
            "## What each column means",
            "- **Wall Duration**: end-to-end latency seen by the client (curl).",
            "- **Azure Duration**: time reported by Azure metrics (server-side execution).",
            "- **Diff Duration** = Wall - Azure: overhead outside the function body (network, platform scheduling, cold starts, etc.).",
            "",
            "## Data integrity checks",
            f"- Rows parsed: **{len(df_off)}** (no_node_options), **{len(df_on)}** (with_node_options).",
            f"- Max absolute error between provided Diff and computed (Wall - Azure): **{max_abs_err:.9f}** (≈0 indicates consistent naming).",
            "",
            "## Summary statistics",
            to_md_table(summary_wall, "Wall Duration (seconds)"),
            to_md_table(summary_azure, "Azure Duration (seconds)"),
            to_md_table(summary_diff, "Diff Duration (seconds)"),
            "",
        ]
        with open(args.out_md, "w", encoding="utf-8") as f:
            f.write("\n".join(md_parts))


if __name__ == "__main__":
    main()
