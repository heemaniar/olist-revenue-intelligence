# Olist dashboard — Evidence.dev (code-based BI)

A 5-page revenue & CX dashboard built **as code** with [Evidence](https://evidence.dev):
SQL + markdown → a static site, querying the dbt marts via DuckDB. The git-versioned,
no-GUI counterpart to the Data Studio / Tableau builds.

**Pages:** Executive overview · Delivery & Satisfaction · Sellers & Categories ·
Voice of Customer (AI) · Metric Definitions.

## Run it
```bash
# 1. ensure the mart extracts exist (one step, from the repo root):
python export_marts.py            # writes ../tableau/*.csv (the marts)

# 2. build + serve:
cd evidence
npm install
npm run sources                   # CSV → parquet (reads ../tableau/*.csv)
npm run dev                       # http://localhost:3000
```

## Publish (free)
`npm run build` → deploy the static `build/` to Netlify / Vercel / GitHub Pages, or use
Evidence Cloud. The data is baked into the build, so the published site needs no warehouse.

## Notes
- **Data source:** DuckDB (in-memory) over `../tableau/*.csv`. To go live on BigQuery
  instead, swap `sources/olist/connection.yaml` to the `bigquery` connector.
- The `tableau/` CSVs and `node_modules/`, `build/`, `.evidence/` are gitignored
  (regenerable). Only the dashboard *code* is committed.
