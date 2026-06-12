"""
export_marts.py — Export the Olist dbt marts from BigQuery to tidy CSVs.

Tableau Public (the free tier) can't connect live to BigQuery, so we land the
reporting marts as flat files it can ingest directly. Same marts the Data Studio
build sits on — so the Tableau and Data Studio dashboards stay consistent.

Output: ./tableau/<mart>.csv  (UTF-8, no index, ISO dates)

Run (venv with google-cloud-bigquery + pandas):
    export BQ_PROJECT=mallpulse-hackathon BQ_DATASET=olist_core
    python export_marts.py
    python export_marts.py --out tableau --marts fct_orders review_themes   # subset

Then in Tableau Public: Connect → Text File → pick a CSV (join/relate in the UI).
The ./tableau/ folder is regenerable — gitignore it (or commit the small aggregates
if you want the workbook fully reproducible).
"""

import argparse
import os
from pathlib import Path

import pandas as pd
from google.cloud import bigquery

PROJECT = os.getenv("BQ_PROJECT") or os.getenv("GOOGLE_CLOUD_PROJECT")
DATASET = os.getenv("BQ_DATASET", "olist_core")

# Dashboard-facing marts (the reporting layer), not the raw/staging tables.
MARTS = [
    "fct_orders",            # order grain — main fact
    "fct_order_items",       # item grain — category drill (no category on fct_orders)
    "revenue_monthly",
    "delivery_review",
    "seller_performance",
    "category_performance",
    "state_performance",
    "dim_customers",
    "review_themes",         # AI Voice-of-Customer
    "metric_definitions",    # KPI dictionary (SSOT) → Definitions sheet
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="tableau", help="output directory")
    ap.add_argument("--marts", nargs="*", default=MARTS, help="subset of marts to export")
    args = ap.parse_args()
    if not PROJECT:
        raise SystemExit("Set BQ_PROJECT or GOOGLE_CLOUD_PROJECT.")

    out_dir = Path(__file__).resolve().parent / args.out
    out_dir.mkdir(parents=True, exist_ok=True)
    bq = bigquery.Client(project=PROJECT)

    print(f"Exporting {len(args.marts)} marts from {PROJECT}.{DATASET} → {out_dir}/\n")
    total = 0
    for mart in args.marts:
        try:
            df = bq.query(f"SELECT * FROM `{PROJECT}.{DATASET}.{mart}`").to_dataframe()
        except Exception as e:
            print(f"  ⚠️  {mart}: {str(e)[:80]} — skipped")
            continue
        path = out_dir / f"{mart}.csv"
        df.to_csv(path, index=False, encoding="utf-8")
        size_kb = path.stat().st_size / 1024
        print(f"  ✅ {mart:<22} {len(df):>7,} rows  ({size_kb:,.0f} KB)")
        total += len(df)

    print(f"\nDone. {total:,} rows across {len(args.marts)} files in {out_dir}/")
    print("Tableau Public → Connect → Text File → select a CSV; relate them on keys "
          "(order_id, seller_id, category, customer_unique_id, review_id).")


if __name__ == "__main__":
    main()
