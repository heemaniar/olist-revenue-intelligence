# Data Studio build guide — Olist Revenue & CX Intelligence

Builds the 5-page dashboard on the **dbt marts** in `mallpulse-hackathon.olist_core`.
Every field below is a real mart column (verified), so it's drag-and-drop — no SQL
in the UI. Budget ~40 min. Screenshot pages 2 & 4 into `docs/screenshots/` when done.

> All marts already exist (`dbt build` is green). This guide only assembles the report.

---

## 0. Connect sources + one-time formatting

**Add data → BigQuery → `mallpulse-hackathon` → `olist_core`**, add each as a
**separate** data source:
`fct_orders` (main), `revenue_monthly`, `delivery_review`, `seller_performance`,
`category_performance`, `state_performance`, `dim_customers`, `review_themes`,
`metric_definitions`.

Format **once** at the data-source level (gear/edit on each source):
- **Percent** type on all rate fields: `on_time_rate`, `late_rate`, `detractor_rate`,
  `freight_to_price`, `gmv_share`, `gmv_cumulative_share`.
- `is_late` → relabel values **Late / On-time** (or wrap in a calc field, below).
- `purchase_month`, `purchase_date`, `first_order_date`, `last_order_date` → type **Date**.
- `gmv`, `net_revenue`, `aov`, `lifetime_gmv`, `freight` → **Currency (USD)**.

**Calculated fields to create on `fct_orders`** (Add field):
- `On-Time %` = `AVG(IF(is_late, 0, 1))`
- `AOV` = `SUM(gmv) / COUNT_DISTINCT(order_id)`
- `Detractor %` = `AVG(IF(review_score <= 2, 1, 0))`

**On `dim_customers`:**
- `Repeat %` = `AVG(IF(is_repeat, 1, 0))`

> Tip: set a clean light theme. Add a **date-range control** on each page bound to
> `purchase_date` (fct_orders) / `purchase_month` (revenue_monthly).

---

## Page 1 — Executive Revenue Overview
**Source: `fct_orders`** (+ `revenue_monthly`, `dim_customers`)

**Scorecards** (Insert → Scorecard):

| Metric | Field | Format |
|---|---|---|
| GMV | `SUM(gmv)` | currency |
| Net Revenue | `SUM(net_revenue)` | currency |
| Orders | `COUNT_DISTINCT(order_id)` | integer |
| AOV | `AOV` (calc) | currency |
| On-Time % | `On-Time %` (calc) | percent |
| Avg Review | `AVG(review_score)` | 2 decimals |
| Repeat % | `Repeat %` (source `dim_customers`) | percent |

> **Repeat % ≈ 3% is real, not a bug** — Olist is an acquisition-heavy, low-repeat
> marketplace. Call it out; it's a finding (weak retention).

**GMV over time** — Time series, source **`revenue_monthly`**: dimension
`purchase_month`, metric `gmv`. Add a second series `orders` if you want volume.

**Controls** (Insert → Drop-down): `customer_state`, `primary_payment_type`, date range.
*(Category filter: see the grain note at the bottom.)*

---

## Page 2 — Delivery & Satisfaction *(the headline)*
**Source: `delivery_review` + `delivery_stages` + `distance_delivery` + `state_performance`**

**Avg review by delivery-days bucket** *(money chart)* — Column/Bar or Line, source
**`delivery_review`**: dimension `delivery_bucket`, metric `avg_review`.
→ the line/bars **drop as delivery slows** — the core "late delivery kills
satisfaction" story.
⚠️ Sort the `delivery_bucket` axis in true delivery order (ascending). If the bucket
labels don't sort naturally (e.g. "15+" lands before "4-7"), set **Sort → Manual** or
add an order helper.

**Late % by bucket** — same source, add `late_rate` as a second metric (percent).

**Delivery decomposition: handling vs carrier transit** *(high-value)* — Clustered bar,
source **`delivery_stages`**: dimension `delivery_status` (On-time/Late), metrics
`avg_handling_days` + `avg_transit_days`. → on the Late bar, **transit explodes (25.7 vs
7.8 d) while handling barely moves** — proof lateness is a *carrier* problem, not seller
dispatch. The most decision-useful tile on the page.

**Distance → delivery & satisfaction** — source **`distance_delivery`**: dimension
`distance_band` (sort by `band_order`), metrics `avg_delivery_days` and `avg_review`
(dual-axis combo, or two small bars). → the clean distance↑ → days↑ → review↓ chain.

**On-Time % by state** — Bar, source **`state_performance`**: dimension `state`,
metric `on_time_rate` (percent), sorted desc.

**Delivery-gap distribution** — Histogram/Bar, source `fct_orders`: dimension
`delivery_gap_days` (negative = early, positive = late), metric `Record Count`.

---

## Page 3 — Sellers & Categories
**Source: `seller_performance` + `category_performance`**

**Seller Pareto** — Combo chart, source **`seller_performance`**:
- dimension `seller_id`, metric `gmv` (bars, sorted desc, top 20)
- secondary axis line: `gmv_cumulative_share` (percent) → the Pareto curve.

**Category: GMV × satisfaction bubble** — Scatter, source **`category_performance`**:
- X `gmv`, Y `avg_review`, bubble size `orders`, color/label `category`.
→ big bubbles low on the Y axis = high-revenue, low-satisfaction categories to fix.

**Freight burden by category** — Bar, source `category_performance`: dimension
`category`, metric `freight_to_price` (percent), sorted desc, top 15.

---

## Page 4 — Voice of Customer (AI) *(the differentiator)*
**Source: `review_themes`**

**Avg review score by theme** *(standout tile)* — Bar, **ascending**: dimension
`theme`, metric `AVG(review_score)`.
→ surfaces **wrong_or_missing_item (~1.7★)** and **not_as_described (~2.5★)** as the
real pain points — accuracy issues that score *lower* than delivery. This is the
insight the star ratings alone couldn't separate.

**Theme volume** — Bar: dimension `theme`, metric `COUNT_DISTINCT(review_id)`, desc.

**Theme × sentiment** — Stacked bar: dimension `theme`, breakdown `sentiment`,
metric `COUNT_DISTINCT(review_id)`.

**Sample complaints** — Table: dimensions `theme`, `summary_en`; filter
`sentiment = negative`; sort by theme. (Shows the English summaries Claude produced.)

> **Caption (be transparent):** *"AI-tagged sample of N reviews."* N = **629 now**;
> if the 1,500-review rerun has completed, update to ~1,500. Check:
> `SELECT COUNT(DISTINCT review_id) FROM olist_core.review_themes`.

---

## Page 5 — Definitions (SSOT)
**Source: `metric_definitions`** — Table with dimensions (no metric):
`kpi`, `definition`, `calculation`, `population`, `target`, `owner`. Wrap text, bold
header, pagination off. Header note: *"One definition per KPI — every tile uses these."*
*(If Data Studio demands a metric, add hidden Record Count.)*

---

## Finishing touches
- Percent-format every rate field; relabel `is_late` → Late/On-time.
- **Footer (page 1):** *"Synthetic-for-demo? No — this is the real Olist public
  dataset. Data © Olist, licensed CC BY-NC-SA 4.0; used here for non-commercial
  portfolio demonstration."*
- Add a **"ⓘ Definitions"** text link on each page → Page 5.
- **Screenshot pages 2 and 4** (strongest) into `docs/screenshots/`; I'll embed them
  in the README on publish.

---

## ⚠️ Grain note — category filters
`fct_orders` is **order-grain** and has **no `category`** column (category lives at
*item* grain). So:
- For **category views**, use the pre-aggregated **`category_performance`** mart
  (Page 3) — don't try to pull category off `fct_orders`.
- To **filter the whole exec page by category**, you'd need to blend `fct_orders`
  with `fct_order_items` on `order_id` (Resource → Manage blends). Simpler for the
  demo: skip a category control on Page 1 and let Page 3 carry category analysis.
