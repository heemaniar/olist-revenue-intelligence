# Code Map

A reading guide for this repo. The code is intentionally small — the size is in the
*number* of files, not the complexity of any one. Read it in dataflow order and it's
linear. Start here, not in the file tree.

## The one-sentence version

CSVs → **`load_bigquery.py`** lands them raw in BigQuery → **dbt** transforms them in
three layers (staging → intermediate → marts) → the marts feed three things: the
**Evidence dashboard**, **`export_marts.py`** (CSVs for Tableau), and
**`analyze_reviews.py`** (Claude tags reviews → `review_themes`).

```
data/*.csv
   │  load_bigquery.py        (EL — typed raw tables)
   ▼
BigQuery: raw tables
   │  dbt build
   ▼
 staging/   (1:1 clean + rename, one row per source entity)
   ▼
 intermediate/  (collapse fan-out: items/payments/reviews → one row per order)
   ▼
 marts/     (fct_orders spine + dims + reporting aggregates)
   │
   ├──► Evidence dashboard (live on Netlify)
   ├──► export_marts.py  → tableau/*.csv
   └──► analyze_reviews.py (Claude) → review_themes mart
```

## Read in this order (≈20 min to understand the whole project)

1. **`README.md`** — what and why, the modeling decisions, the live links.
2. **`load_bigquery.py`** — how raw data gets in. The `TABLES` dict is the whole schema.
3. **`dbt/models/marts/fct_orders.sql`** — the centre of gravity. One row per order,
   joining the four `int_` aggregates + customer. If you understand this join, you
   understand the model. The `int_` and `stg_` files it `ref`s are each <35 lines.
4. **`dbt/models/marts/delivery_review.sql`** — the headline analysis (does late
   delivery drag review scores?). This is the "so what."
5. **`analyze_reviews.py`** — the AI layer. Read `SYSTEM` + `SCHEMA` first (that's the
   prompt contract), then `classify()`, then `main()`.

Everything else is a variation on these patterns.

## The layers, in one line each

| Layer | Folder | Rule | Grain |
|-------|--------|------|-------|
| **staging** | `dbt/models/staging/` | Clean + rename only, no business logic | one row per source entity |
| **intermediate** | `dbt/models/intermediate/` | Collapse fan-out *before* joining | one row per order |
| **marts** | `dbt/models/marts/` | Joins + aggregates the dashboard reads | varies (order / seller / category / state) |

**Why intermediate exists:** items and payments have many rows per order. Aggregating
them to order-grain *before* joining to `fct_orders` is what prevents double-counting
GMV. `dbt/tests/assert_gmv_integrity.sql` enforces that modeled GMV == raw item revenue.

## Files by job

**Pipeline (run in this order)**
- `load_bigquery.py` — EL: CSVs → raw BigQuery tables.
- `dbt build` (in `dbt/`) — staging → intermediate → marts, with tests.
- `analyze_reviews.py` — Claude tags a review sample → `review_themes` mart.
- `export_marts.py` — dump marts to `tableau/*.csv` for Tableau Public.

**dbt models**
- `staging/` — `stg_orders`, `stg_order_items`, `stg_payments`, `stg_reviews`,
  `stg_customers`, `stg_sellers`, `stg_products`, `stg_geolocation`.
- `intermediate/` — `int_order_items`, `int_order_payments`, `int_order_delivery`,
  `int_order_reviews`, `int_order_distance` (all collapse to order grain).
- `marts/` — `fct_orders` (spine), `fct_order_items`, `dim_customers/sellers/products`,
  and the reporting aggregates (`revenue_monthly`, `seller_performance`,
  `category_performance`, `state_performance`, `delivery_review`, `delivery_stages`,
  `distance_delivery`, `review_themes`).

**Config / contracts**
- `dbt/dbt_project.yml`, `dbt/profiles.yml` — dbt setup; `valid_order_status` var lives here.
- `dbt/models/**/_*.yml` — column docs + tests per layer.
- `dbt/tests/assert_gmv_integrity.sql` — the no-double-count guard.

**Docs (read as needed, not to understand the code)**
- `METRICS.md` — KPI definitions (single source of truth).
- `DECISION_BRIEF.md` — the leadership-facing "what to do about it."
- `BUILD_GUIDE.md`, `PROMPTS.md`, `TABLEAU_GUIDE.md`, `DATA_STUDIO_GUIDE.md` — build notes.

## Conventions that make the code readable
- Every dbt model's first line is a comment stating its **grain and purpose**.
- Staging renames timestamps to `*_at` and strips redundant prefixes (`seller_city` → `city`).
- Python scripts: module docstring says what/why + how to run; config lives in a dict at
  the top (`TABLES`, `MARTS`, `THEMES`); a single `main()` does the work.
- `customer_unique_id` (the real person) ≠ `customer_id` (per-order). Repeat-purchase
  uses the former — see README modeling decisions.
