# Metrics Dictionary — Olist Revenue & CX Intelligence

The **single source of truth** for every KPI on the dashboard. Each definition is
also loaded into the warehouse (`metric_definitions` seed) and surfaced on the
dashboard's **Definitions** page, so the docs, the warehouse, and the dashboard
never drift. Current values are from the latest `dbt build` (real Olist data, 2016–2018).

> **Revenue scope:** "valid orders" = `order_status in (delivered, shipped, invoiced, processing, approved)` — i.e. orders that represent real demand (excludes `canceled`, `unavailable`, `created`). GMV **excludes freight**.

| # | KPI | Definition | Calculation | Population | Current | Target | Owner |
|---|-----|------------|-------------|------------|---------|--------|-------|
| 1 | **GMV** | Item revenue (excludes freight). | `SUM(price)` | Valid orders | **R$13.5M** | grow | Revenue |
| 2 | Net Revenue | Item revenue + freight paid. | `SUM(price + freight_value)` | Valid orders | — | grow | Revenue |
| 3 | **Orders** | Distinct valid orders. | `COUNT(DISTINCT order_id)` | Valid orders | **98,202** | grow | Revenue |
| 4 | **AOV** | Average order value. | `GMV / Orders` | Valid orders | **R$137.4** | grow | Revenue |
| 5 | **On-Time Delivery %** | Delivered on/before the estimate. | `AVG(IF(NOT is_late,1,0))` | Delivered orders | **91.9%** | ≥ 90% | Logistics |
| 6 | Avg Delivery Days | Purchase → delivery. | `AVG(delivery_days)` | Delivered orders | — | reduce | Logistics |
| 7 | **Avg Review Score** | Mean 1–5 satisfaction (CSAT analog). | `AVG(review_score)` | Reviewed orders | **4.12** | ≥ 4.2 | CX |
| 8 | Detractor % | Share of 1–2★ reviews. | `AVG(IF(review_score<=2,1,0))` | Reviewed orders | — | < 15% | CX |
| 9 | **Repeat-Purchase %** | Customers with >1 order (by `customer_unique_id`). | `AVG(IF(orders>1,1,0))` | `dim_customers` | **3.1%** | grow | Growth |
| 10 | Freight-to-Price % | Shipping cost vs item revenue. | `SUM(freight)/SUM(price)` | Valid orders | — | monitor | Logistics |
| 11 | **Seller GMV Concentration** | GMV share of the top 10% of sellers. | top-decile GMV ÷ total GMV | `seller_performance` | **67.5%** | monitor | Revenue |
| 12 | Cancellation % | Share of orders canceled. | `AVG(IF(order_status='canceled',1,0))` | All orders | — | < 1% | Ops |

## Why these definitions matter (governance)
- **Customer identity:** Repeat-Purchase uses `customer_unique_id`, **not** the per-order `customer_id`. With `customer_id` it would read ~0% (every order looks like a new customer). The real ~3% is the correct, defensible figure.
- **Fan-out integrity:** GMV is aggregated to order grain before joining; a dbt **singular test** (`assert_gmv_integrity`) proves modeled GMV equals raw item revenue — no double-counting.
- **One definition, one place:** change a definition → edit `dbt/seeds/metric_definitions.csv` → `dbt seed` → docs + dashboard update together.
