# Olist Revenue & CX Intelligence — Build Guide

A strategic-analyst portfolio project: turn raw Brazilian-marketplace data into a
**governed, decision-driving** revenue + customer-experience analytics product.

Same playbook as the Ops Productivity project, **new business function (Revenue/CX)
and real, messy data** — which is exactly the gap a synthetic project can't fill.

**Stack:** Kaggle CSVs → BigQuery (EL) → **dbt** (staging → intermediate → marts, tested + documented) → **Data Studio**, with a **Python + Claude** layer for Portuguese review NLP.

> Dataset: [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — ~100k real (anonymised) orders, 2016–2018, 9 relational CSVs (~120 MB). License: CC BY-NC-SA 4.0 (portfolio/non-commercial use is fine; keep the attribution).

---

## 1. What this project proves (role mapping)

Target role: **strategic analyst who does light data engineering, drives decisions with leadership, and uses AI.** This project demonstrates each:

| Competency | How it shows up here |
|---|---|
| Light-to-mid data engineering | EL into BigQuery + **dbt** with a real staging→intermediate→marts model |
| Single source of truth | `METRICS.md` KPI dictionary + a warehouse `metric_definitions` seed + a Definitions dashboard page |
| Dimensional modeling | 9 normalised tables → a clean star schema (the strongest analytics-eng signal) |
| Decisions with leadership | a `DECISION_BRIEF.md` one-pager that says *what to do*, not just what happened |
| Cross-functional range | a **second** business function (Revenue/CX) beside the Ops project |
| AI / prompt engineering | Claude over Portuguese reviews → structured themes/sentiment (a real, defensible LLM use) |
| Real messy data | fan-out joins, dedup, Portuguese, nulls, customer-identity gotchas |

---

## 2. The data (9 tables) + the gotchas that make it a real exercise

| Table | Grain | Key columns |
|---|---|---|
| `olist_orders_dataset` | order | order_id, customer_id, order_status, purchase/approved/delivered/**estimated** timestamps |
| `olist_order_items_dataset` | order × item | order_id, order_item_id, product_id, seller_id, **price**, **freight_value** |
| `olist_order_payments_dataset` | order × payment | order_id, payment_type, installments, **payment_value** |
| `olist_order_reviews_dataset` | review | review_id, order_id, **review_score** (1–5), comment_title, **comment_message** (PT) |
| `olist_customers_dataset` | order-customer | customer_id, **customer_unique_id**, zip, city, state |
| `olist_sellers_dataset` | seller | seller_id, zip, city, state |
| `olist_products_dataset` | product | product_id, **product_category_name** (PT), dims, weight |
| `olist_geolocation_dataset` | zip prefix (many rows) | zip_prefix, lat, lng, city, state |
| `product_category_name_translation` | category | category_name (PT) → category_name_english |

**The four gotchas to model correctly (and document — they're your interview talking points):**

1. **`customer_id` ≠ a customer.** It's issued **per order**. The real person is `customer_unique_id`. Repeat-purchase / retention **must** use `customer_unique_id`, or you'll report ~0% repeat. *(This is the #1 Olist trap.)*
2. **Payments and items fan out** (multiple rows per order). Aggregate them to order grain **before** joining to `orders`, or GMV double-counts.
3. **Reviews can have >1 row per order.** Dedup to one (latest by review_creation_date).
4. **Geolocation has many rows per zip prefix.** Dedup / average lat-lng before joining, or every customer join explodes.

Plus: define **"revenue" explicitly** — GMV = `SUM(item price)` (excl. freight); net-of-freight is a separate metric; only count valid/`delivered` orders. Putting this in the KPI dictionary *is* the single-source-of-truth value.

---

## 3. Repo structure

```
olist-revenue-intelligence/
├── README.md                 # positioning + live links + screenshots
├── BUILD_GUIDE.md            # this file
├── METRICS.md                # KPI dictionary (SSOT)
├── DECISION_BRIEF.md         # leadership one-pager
├── PROMPTS.md                # the review-NLP prompt design (prompt-eng showcase)
├── requirements.txt
├── load_bigquery.py          # EL: land the 9 raw CSVs as dbt sources
├── analyze_reviews.py        # Claude → structured review themes/sentiment → BQ
├── data/                     # Kaggle CSVs (gitignored)
└── dbt/
    ├── dbt_project.yml
    ├── profiles.yml
    ├── seeds/metric_definitions.csv
    └── models/
        ├── staging/      stg_*.sql + _sources.yml + _staging.yml
        ├── intermediate/ int_*.sql
        └── marts/        fct_/dim_/ reporting marts + _marts.yml
```

(Reuse `dbt_project.yml`, `profiles.yml`, `.gitignore`, and the `load_bigquery.py` skeleton from the Ops project — same BigQuery/oauth setup, `BQ_DATASET=olist_core`.)

---

## 4. dbt model plan

### DAG
```
sources (9 raw)        seeds
   │                metric_definitions
   ▼
staging  stg_orders, stg_order_items, stg_payments, stg_reviews,
         stg_customers, stg_sellers, stg_products (+EN category), stg_geolocation
   │
   ▼
intermediate
   int_order_items     (items → order grain: gmv, freight, n_items, n_sellers)
   int_order_payments  (payments → order grain: paid_value, installments, payment_type)
   int_order_delivery  (delivery_days, estimated_days, is_late, delivery_gap_days)
   int_order_reviews   (one review/order: score, has_comment)
   │
   ▼
marts
   fct_orders          ← spine: one row/order (the dashboard grain)
   fct_order_items     ← item grain (product/seller analysis)
   dim_customers       ← customer_unique_id grain (repeat/retention)
   dim_sellers, dim_products
   revenue_monthly · seller_performance · category_performance
   delivery_review · state_performance · review_themes (from Claude)
```

### Materialization
- staging + intermediate → **view**
- marts → **table** (small data; tables are snappy for Data Studio)

### The three models worth getting right (sketches)

**`int_order_items` — kill the fan-out before joining:**
```sql
select
    order_id,
    count(*)                       as n_items,
    count(distinct seller_id)      as n_sellers,
    count(distinct product_id)     as n_products,
    round(sum(price), 2)           as gmv,            -- item revenue (excl freight)
    round(sum(freight_value), 2)   as freight,
    round(sum(price + freight_value), 2) as paid_items_total
from {{ ref('stg_order_items') }}
group by order_id
```

**`int_order_delivery` — the late→satisfaction backbone:**
```sql
select
    order_id,
    date_diff(date(delivered_customer_at), date(purchase_at), day)        as delivery_days,
    date_diff(date(estimated_delivery_at), date(purchase_at), day)        as promised_days,
    date_diff(date(delivered_customer_at), date(estimated_delivery_at), day) as delivery_gap_days,
    delivered_customer_at > estimated_delivery_at                         as is_late
from {{ ref('stg_orders') }}
where delivered_customer_at is not null
```

**`dim_customers` — use the real identity for repeat-purchase:**
```sql
with c as (select distinct customer_id, customer_unique_id, customer_state from {{ ref('stg_customers') }}),
o as (select customer_id, count(*) over (partition by /* via unique id */ 1) from ...)  -- map order→customer_id→customer_unique_id
select
    customer_unique_id,
    any_value(customer_state)              as state,
    count(distinct order_id)               as orders,
    count(distinct order_id) > 1           as is_repeat,
    round(sum(gmv), 2)                      as lifetime_gmv
from {{ ref('fct_orders') }} f
join c using (customer_id)
group by customer_unique_id
```

`fct_orders` then joins `orders` + the four `int_` models + review + customer/state, and applies the **revenue status filter** (`order_status in ('delivered','shipped','invoiced')` — define and document).

### Tests (the data-quality story)
- `unique` + `not_null` on every PK (order_id, customer_unique_id, seller_id, product_id, review per order).
- `relationships`: order_items.order_id → orders; reviews.order_id → orders; products.category → translation.
- `accepted_values`: order_status, payment_type, review_score (1–5).
- A **singular test**: assert `fct_orders` GMV total == `SUM(price)` from raw items (proves the fan-out aggregation didn't drop/double-count revenue). This is the test that impresses.

---

## 5. KPI dictionary (`METRICS.md` + `metric_definitions` seed = SSOT)

Starter set — each row becomes a `metric_definitions` seed row and a `METRICS.md` entry, exactly like the Ops project:

| KPI | Definition | Calculation | Population |
|---|---|---|---|
| GMV | Item revenue (excludes freight). | `SUM(price)` | Valid orders |
| Net Revenue | Item + freight paid. | `SUM(price + freight_value)` | Valid orders |
| Orders | Distinct valid orders. | `COUNT(DISTINCT order_id)` | Valid orders |
| AOV | Avg order value. | `GMV / Orders` | Valid orders |
| On-Time Delivery % | Delivered on/before estimate. | `AVG(IF(NOT is_late,1,0))` | Delivered orders |
| Avg Delivery Days | Purchase → delivery. | `AVG(delivery_days)` | Delivered orders |
| Avg Review Score | 1–5 satisfaction (CSAT analog). | `AVG(review_score)` | Reviewed orders |
| Detractor % | Share of 1–2★ reviews. | `AVG(IF(review_score<=2,1,0))` | Reviewed orders |
| Repeat-Purchase % | Customers with >1 order. | `AVG(IF(orders>1,1,0))` | `dim_customers` |
| Freight-to-Price % | Shipping cost burden. | `SUM(freight)/SUM(price)` | Valid orders |
| Seller GMV Concentration | Top-10% sellers' GMV share. | top-decile GMV ÷ total GMV | `seller_performance` |
| Cancellation % | Cancelled orders. | `AVG(IF(status='canceled',1,0))` | All orders |
| Review Theme Volume | Tagged complaint/praise themes (AI). | `COUNT` by theme | `review_themes` |

---

## 6. AI layer — Claude over Portuguese reviews (`analyze_reviews.py` + `PROMPTS.md`)

**Goal:** turn ~40k free-text Portuguese review comments into a structured `review_themes` mart so the dashboard can answer *"what do customers actually complain about, by category?"*

**Design (the prompt-engineering showcase):**
- **Structured output** (JSON schema) per review: `{ sentiment: positive|neutral|negative, themes: [delivery, product_quality, not_as_described, packaging, customer_service, price, other], summary_en: string }`.
- **Prompt caching** on the system prompt (the fixed taxonomy + instructions) — stable prefix, cached across calls.
- **Multilingual:** input is Portuguese; ask for English theme tags + a one-line English summary.
- **DECISION (locked): sample, not full.** Score a **stratified ~2,500-review sample** (proportional by `category_english`), filtering to comments with real text (e.g. `LENGTH(comment_message) >= 15`). Enough to populate every category on the VoC page without a big bill.
- At ~2,500 the run is small enough to go **synchronous** (sequential calls, a few minutes — same shape as the Ops `ml_classify.py`); Batches API is optional and only worth it for the full ~40k.
- Join the per-review themes back to `fct_orders` → `review_themes` mart (category × theme × sentiment × count).

**Cost:** the locked **~2,500 sample ≈ $1** on Haiku. (Full ~40k via Batches ≈ $10 — not doing this for now.) Document the choice + sampling logic in `PROMPTS.md`.

Mirror the Ops project's `ml_classify.py` patterns: `output_config.format` enum/schema, cached system block, graceful per-call error handling.

---

## 7. Dashboard (Data Studio) — 5 pages

1. **Executive Revenue Overview** — scorecards (GMV, Net Revenue, Orders, AOV, On-Time %, Avg Review, Repeat %); GMV over time; controls (date, state, category, payment_type).
2. **Delivery & Satisfaction** *(the headline)* — **avg review score by delivery-days bucket** (the late→satisfaction story); On-Time % by state; estimated-vs-actual gap distribution; review-score distribution.
3. **Sellers & Categories** — seller **Pareto** (GMV share); category GMV × avg-review matrix (bubble); freight-to-price by category.
4. **Voice of Customer (AI)** — review **themes by category** (from Claude); sentiment mix; sample translated complaints. *This is the differentiator page.*
5. **Definitions** — the `metric_definitions` table (SSOT), same pattern as Ops.

Each rate field formatted as **Percent**; `true/false` flags relabeled; footer disclaimer + dataset attribution.

---

## 8. Decision brief (`DECISION_BRIEF.md`)

The one-pager will argue something like (validate against real numbers when built):
- **Finding 1 — Late delivery is the satisfaction killer.** On-time orders average ~X★; late orders ~Y★ (−Z). Late rate is W%, concentrated in states A/B and category C. → *Invest in logistics SLA for those lanes; projected review-score lift and repeat-purchase impact.*
- **Finding 2 — Revenue is seller-concentrated.** Top 10% of sellers drive ~N% of GMV. → *Seller-success program for the long tail / protect the top.*
- **Finding 3 — Complaint themes are fixable.** AI tags show "not as described" + "late" dominate negative reviews in category C. → *Tighten listing accuracy + delivery for C.*

Format: 1 page, 3 findings, each with **evidence → recommendation → projected impact**.

---

## 9. Implementation plan (phased)

| Phase | Work | Output | Est. |
|---|---|---|---|
| 0 | Repo + venv + gcloud ADC + `BQ_DATASET=olist_core`; copy dbt skeleton from Ops | scaffolding | 1h |
| 1 | Download Kaggle data; `load_bigquery.py` lands 9 raw tables | sources in BQ | 1–2h |
| 2 | dbt staging → intermediate → marts + tests + docs | `dbt build` green, lineage DAG | 1 day |
| 3 | `METRICS.md` + `metric_definitions` seed; validate KPI numbers vs raw | SSOT | 2–3h |
| 4 | `analyze_reviews.py` (Claude) → `review_themes` mart | AI layer | 3–4h |
| 5 | Data Studio dashboard (5 pages) + screenshots | live dashboard | half day |
| 6 | `DECISION_BRIEF.md` + README + publish (LICENSE, topics, push) | public repo | 2–3h |

**Total: ~2–4 focused days.**

---

## 10. Cost basis

- **BigQuery:** ~120 MB raw → storage and queries are **free-tier** (10 GB storage / 1 TB queries per month). Effectively **$0**.
- **Claude review NLP:** ~**$1** (locked ~2,500-review sample, Haiku, synchronous).
- **Kaggle / Data Studio:** free.
- **Net: ≈ $1 total.**

---

## 11. Modeling decisions to document (your interview talking points)

Keep a short "Decisions" section in the README:
1. **Customer identity** — used `customer_unique_id` (not `customer_id`) for repeat-purchase; explain why.
2. **Fan-out control** — aggregated items/payments to order grain before joining; the singular test proves GMV integrity.
3. **Revenue definition** — GMV excludes freight; valid-order status filter; documented in `METRICS.md`.
4. **Review dedup** — one (latest) review per order.
5. **Geolocation dedup** — averaged lat-lng per zip prefix.
6. **AI scope** — sampled vs full, structured output, cached prompt, Batches for cost.

---

## 12. Definition of done
- [ ] `dbt build` green (models + tests + docs); lineage DAG screenshot
- [ ] KPI numbers reconcile to raw (singular GMV test passes)
- [ ] `METRICS.md` ↔ `metric_definitions` seed in sync (same KPI set)
- [ ] `review_themes` mart populated from Claude; PROMPTS.md documents the prompt
- [ ] 5-page Data Studio dashboard, percent-formatted, attributed, screenshots in `docs/`
- [ ] `DECISION_BRIEF.md` with 3 evidence→recommendation→impact findings
- [ ] README with live link + screenshots; LICENSE; topics; pushed to a **new** GitHub repo (separate from ops + mallpulse)

---

### Sources
- [Olist dataset (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- Reuse: Ops project's dbt setup, `load_bigquery.py`, KPI-dictionary + decision-brief patterns.
