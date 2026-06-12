# Tableau Public build guide — Olist Revenue & CX Intelligence

The same 5-page dashboard as `DATA_STUDIO_GUIDE.md`, built in **Tableau Public** on the
CSV extracts in `./tableau/` (run `python export_marts.py` to (re)generate them). Tableau
Public can't connect live to BigQuery, so we build on the flat marts — and Tableau does
several things *better* (native Brazil maps, date reference lines, highlight-table heatmaps).

Budget ~60 min. When done: **File → Save to Tableau Public As…** → it publishes and gives a
public URL. Screenshot pages 2 & 4 into `docs/screenshots/`.

---

## 0. Connect + data model + calculated fields

**Connect:** Open Tableau Public → **Connect → Text File** → pick `tableau/fct_orders.csv`.
Add the rest with **Data → New Data Source** (each CSV = one source). Keep it simple:
**each sheet is built from the one source it needs** (named per tile below). Only `fct_orders`
needs a relationship:

- On the `fct_orders` source, drag **`fct_order_items.csv`** onto the canvas → relate on
  **`order_id`** (gives you item-grain `category` for drill). Optionally relate
  **`review_themes.csv`** on `order_id` too.

**Type fixes (do once):**
- Booleans from CSV often import as **strings** (`"True"`/`"False"`). If `is_late`,
  `is_repeat`, `has_comment`, `is_valid_revenue` show as *Abc* (string), the calcs below
  handle it; if they import as Boolean, drop the `="True"` and use the field directly.
- `state` / `seller_state` → right-click → **Geographic Role → State/Province** (Map →
  Edit Locations → Country = **Brazil**).
- `purchase_date`, `purchase_month` → **Date**; money fields → currency number format.

**Calculated fields** (Analysis → Create Calculated Field), on `fct_orders`:
```
Valid orders   = SUM(IF [is_valid_revenue]="True" THEN 1 ELSE 0 END)
On-Time %      = SUM(IF [is_late]="False" THEN 1 ELSE 0 END)
                 / SUM(IF [is_late] IN ("True","False") THEN 1 ELSE 0 END)
AOV            = SUM([gmv]) / COUNTD([order_id])
Detractor %    = AVG(IF [review_score] <= 2 THEN 1.0 ELSE 0.0 END)
```
On `dim_customers`:  `Repeat % = SUM(IF [is_repeat]="True" THEN 1 ELSE 0 END) / COUNTD([customer_unique_id])`

> Tableau has no "scorecard" object — a KPI tile is a **sheet with one measure** shown as
> text (BAN, "big-ass-number"): drag the measure to **Text**, hide headers, big font.

---

## Page 1 — Executive Revenue Overview
**Source: `fct_orders`** (+ `revenue_monthly`, `dim_customers`)

**KPI tiles** (one sheet each, measure → Text):
| Tile | Measure |
|---|---|
| GMV | `SUM([gmv])` |
| Net Revenue | `SUM([net_revenue])` |
| Orders | `COUNTD([order_id])` |
| AOV | `AOV` |
| On-Time % | `On-Time %` (format %) |
| Avg Review | `AVG([review_score])` |
| Repeat % | `Repeat %` (source `dim_customers`, format %) |

> **Repeat % ≈ 3% is real** — low-repeat marketplace; label it as a finding.

**GMV over time** — new sheet, source **`revenue_monthly`**: `purchase_month` (continuous,
**Month**) → Columns; `SUM([gmv])` → Rows → line. *(Already trimmed to complete months in the
model — no filter needed.)*

**Filters:** drag `customer_state` and `primary_payment_type` to **Filters** → "Show Filter";
add a date-range filter on `purchase_date`. On the dashboard, set them to apply to relevant sheets.

---

## Page 2 — Delivery & Satisfaction *(the headline)*

**Avg review by delivery bucket** *(money chart)* — source **`delivery_review`**:
`delivery_bucket` → Columns, `AVG([avg_review])` → Rows (bars). Manually order the bucket axis
ascending (drag the pills / right-click → Sort).

**Delivery decomposition (handling vs carrier transit)** *(high-value)* — source
**`delivery_stages`**: `delivery_status` → Columns; `avg_handling_days` and `avg_transit_days`
→ Rows as a **side-by-side (clustered) bar** (Measure Names on Color). → the **Late** bar shows
transit exploding (25.7 vs 7.8 d) while handling barely moves = lateness is a *carrier* problem.

**Distance → delivery & satisfaction** — source **`distance_delivery`**: `distance_band` →
Columns (sort by `band_order`), `avg_delivery_days` → Rows (bars) + `avg_review` → secondary
axis (dual-axis combo) → the distance↑ → days↑ → review↓ chain.

**On-Time % by state** — source **`state_performance`**: `state` → Rows, `AVG([on_time_rate])`
→ Columns, sort desc.

---

## Page 3 — Sellers & Categories

**Seller Pareto** — source **`seller_performance`**: `seller_id` → Columns (sort by `gmv`
desc, filter to **Top 20** by gmv); `SUM([gmv])` → bars; add **`gmv_cumulative_share`** →
secondary axis as a line (dual-axis) → the Pareto curve. *(Cumulative share is precomputed in
the mart — no table calc needed.)*

**Category GMV × satisfaction bubble** — source **`category_performance`**: `gmv` → Columns,
`avg_review` → Rows, **Mark = Circle**, `orders` → Size, `category` → Color/Detail → big bubbles
low on Y = high-revenue, low-satisfaction categories.

**Worst-rated categories** — same source: `category` → Rows, `AVG([avg_review])` → Columns,
sort **ascending**, Top 15.

---

## Page 4 — Voice of Customer (AI) *(differentiator)*
**Source: `review_themes`**

**Avg review score by theme** *(standout)* — `theme` → Rows, `AVG([review_score])` → Columns,
sort **ascending** → surfaces wrong/missing-item + not-as-described as the pain points.

**Theme × sentiment** — `theme` → Rows, `COUNTD([review_id])` → Columns, `sentiment` → Color
(stacked bar).

**Sample complaints** — new sheet (text table): `theme`, `summary_en` → Rows; filter
`sentiment = "negative"`.

> Caption: *"AI-tagged sample of N reviews"* — N = `COUNTD(review_id)` (629 now; ~1,500 after
> the rerun — re-export then refresh the extract).

---

## Page 5 — Definitions (SSOT)
**Source: `metric_definitions`** — text table: drag `kpi`, `definition`, `calculation`,
`population`, `target`, `owner` to **Rows** (all dimensions, no measure). Fit width, wrap text.

---

## Assemble + publish
1. **Dashboard → New Dashboard** for each page (or one scrolling dashboard with containers).
   Drag the relevant sheets in; add a title text object per page.
2. Add filters as dashboard objects; right-click a sheet → **Use as Filter** for interactivity.
3. **Footer text object:** *"Real Olist public dataset, © Olist, CC BY-NC-SA 4.0 — non-commercial
   portfolio demonstration."*
4. **File → Save to Tableau Public As…** → sign in → it publishes and returns a public URL.
   Put that link + screenshots in `README.md`.

## Tableau does these better than Data Studio (lean into them)
- **Brazil maps** — native; just assign the State geographic role (Data Studio fights state codes).
- **Date reference line** — Analytics pane → Reference Line at Nov 2017 for the Black-Friday spike
  (Data Studio needs a shape overlay).
- **Heatmap** (day×hour, from `BONUS_VISUALS_GUIDE.md`) — native Highlight Table.

## Gotchas
- **String booleans:** if `is_late` etc. import as text, use the `="True"` calcs above; if Boolean, simplify.
- **Don't mix grains:** build each sheet from its single named source — the pre-aggregated marts
  (revenue_monthly, *_performance, delivery_*, distance_delivery) are different grains than `fct_orders`.
- **Refresh after the review rerun:** `python export_marts.py` → in Tableau, **Data → Refresh** the
  `review_themes` extract.
