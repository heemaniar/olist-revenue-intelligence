# Olist Revenue & CX Intelligence

Turning raw Brazilian-marketplace data into a **governed, decision-driving** revenue
+ customer-experience analytics product. Same playbook as my Ops Productivity
project — KPI single-source-of-truth, dbt, decision brief, Claude — applied to a
**different business function on real, messy data.**

**Stack:** Kaggle CSVs → BigQuery (EL) → **dbt** (staging → intermediate → marts, tested) → **Data Studio**, with **Python + Claude** for Portuguese review NLP.

> Dataset: [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — ~100k real (anonymised) orders, 2016–2018, 9 relational CSVs. Full design in [`BUILD_GUIDE.md`](BUILD_GUIDE.md).

---

## Status
- ✅ Repo + dbt project scaffolded; **`dbt parse` clean**
- ✅ EL loader (`load_bigquery.py`), 9 typed source tables
- ✅ dbt: 8 staging · 4 intermediate · 10 marts + tests + GMV-integrity singular test
- ⬜ Run against data (download Kaggle CSVs → load → `dbt build`)
- ⬜ KPI dictionary (`METRICS.md`) · review NLP (`analyze_reviews.py`) · dashboard · decision brief

## Quickstart
```bash
# 1. Download the dataset and unzip the 9 CSVs into ./data/
#    https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

# 2. EL — land raw tables in BigQuery (Python 3.x venv)
python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
gcloud auth application-default login
export BQ_PROJECT=mallpulse-hackathon BQ_DATASET=olist_core
python load_bigquery.py

# 3. Transform — build marts + run tests (separate Python 3.12 venv for dbt)
cd dbt && dbt build --project-dir . --profiles-dir .
dbt docs generate --project-dir . --profiles-dir .   # lineage DAG
```

## Model layers
```
sources (9 raw)
   ▼ staging      stg_orders, stg_order_items, stg_payments, stg_reviews,
                  stg_customers, stg_sellers, stg_products, stg_geolocation
   ▼ intermediate int_order_items · int_order_payments · int_order_delivery · int_order_reviews
   ▼ marts        fct_orders · fct_order_items · dim_customers/sellers/products
                  revenue_monthly · seller_performance · category_performance
                  delivery_review · state_performance
```

## Modeling decisions (the interview talking points)
- **Customer identity:** repeat-purchase uses `customer_unique_id`, not the per-order `customer_id` (or it reads ~0%). Expect ~3% repeat — that's real for Olist.
- **Fan-out control:** items & payments aggregated to order grain *before* joining; a singular test asserts modeled GMV == raw item revenue (no drop/double-count).
- **Revenue definition:** GMV excludes freight; valid-order status filter — documented in `METRICS.md`.
- **Dedup:** one (latest) review per order; geolocation averaged per zip prefix.

> ⚠️ 100% real anonymised public data (Olist, CC BY-NC-SA 4.0). For portfolio/demo use.
