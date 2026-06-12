# Bonus visuals — the Olist community staples I skipped

Eight visualizations that show up in most Olist analyses but weren't in my 5-page
build. Each is buildable from the **existing marts** (no new dbt). For every viz:
**why it matters → data → Data Studio steps → Tableau steps.**

> Tableau note: build from the CSVs `export_marts.py` produced in `./tableau/`.
> Data Studio note: connect live to the `olist_core` marts (see DATA_STUDIO_GUIDE.md §0).

---

## 1. Brazil map — orders / revenue / delivery by state
**Why:** the single most common Olist viz; the geolocation data exists *for* this.
A filled map reads instantly where revenue and delivery pain concentrate (SE vs N/NE).
**Data:** `state_performance` (`state`, `orders`, `gmv`, `avg_delivery_days`, `avg_review`).

**Data Studio**
1. Insert → **Google Maps → Filled map** (or Geo chart).
2. Location dimension: `state` → click the field → **Type → Geo → Region**. (If BR state
   codes don't resolve, fall back to a **Bubble map** using `geolocation` lat/lng.)
3. Color metric: `gmv` (then duplicate the tile with `avg_delivery_days` to show pain).
4. Set the map zoom/region to Brazil.

**Tableau**
1. In the `state_performance` source, right-click `state` → **Geographic Role → State/Province**.
2. Set the country context: Map → Edit Locations → Country = **Brazil**.
3. Double-click `state` → Tableau auto-plots the map. Drag `gmv` → **Color**, `orders` → **Size**.
4. Duplicate the sheet, swap Color to `avg_delivery_days` for the delivery view.

---

## 2. Customer vs seller geographic concentration (two maps)
**Why:** a headline Olist finding — **sellers cluster in the Southeast, customers spread
wider**. Side-by-side maps make the supply/demand mismatch (and the distance problem) obvious.
**Data:** customers → `state_performance.state`; sellers → `seller_performance.seller_state`.

**Data Studio:** build two filled maps as in #1 — one from `state_performance` (metric `orders`),
one from `seller_performance` (dimension `seller_state` as Geo→Region, metric `orders`). Place side by side.

**Tableau:** two map sheets (assign State role to `state` and to `seller_state`), `orders` → Size/Color,
then drop both on one dashboard side by side.

---

## 3. Order-status breakdown
**Why:** a basic data-health/funnel view — what share of orders are delivered vs
canceled/unavailable/shipped. Every Olist EDA includes it.
**Data:** `fct_orders` (`order_status`).

**Data Studio**
1. Insert → **Bar chart** (or Pie). Source `fct_orders`.
2. Dimension `order_status`; Metric **Record Count**. Sort descending.
3. Add a scorecard: **Cancellation %** = calc `AVG(IF(order_status="canceled",1,0))`.

**Tableau**
1. `order_status` → Columns; `CNT(order_id)` (or Number of Records) → Rows; sort desc.
2. Quick scorecard: new calc `Cancellation % = SUM(IF [order_status]="canceled" THEN 1 ELSE 0 END)/COUNT([order_id])`.

---

## 4. Payment-type mix + installments distribution
**Why:** Brazil is installment-heavy (credit-card *parcelado* + boleto); a staple slide.
**Data:** `fct_orders` (`primary_payment_type`, `max_installments`).

**Data Studio**
1. **Donut/Bar**: dimension `primary_payment_type`, metric **Record Count**.
2. **Installments histogram**: Bar — dimension `max_installments`, metric **Record Count**, sort by installments asc.
3. Optional: scorecard **Avg installments** = `AVG(max_installments)`.

**Tableau**
1. `primary_payment_type` → Color, Number of Records → Angle (pie) or a simple bar.
2. New sheet: `max_installments` (treat as Discrete dimension) → Columns; Number of Records → Rows.

---

## 5. When do customers buy? — day-of-week × hour heatmap
**Why:** classic operational viz; reveals peak ordering windows for staffing/marketing timing.
**Data:** `fct_orders.purchase_at` (timestamp) → derive weekday + hour.

**Data Studio** (no native heatmap → use a colored pivot table)
1. Create calc fields on `fct_orders`: `Weekday = FORMAT_DATETIME("%A", purchase_at)`,
   `Hour = HOUR(purchase_at)`.
2. Insert → **Pivot table with heatmap**: Row dimension `Weekday`, Column dimension `Hour`,
   Metric **Record Count**, cell color scale on.
3. (Optional) sort Weekday Mon→Sun via a `Weekday #` = `WEEKDAY(purchase_at)` helper.

**Tableau**
1. New calcs: `Weekday = DATENAME('weekday',[purchase_at])`, `Hour = DATEPART('hour',[purchase_at])`.
2. `Hour` → Columns (Discrete), `Weekday` → Rows; **Number of Records → Color** → **Highlight Table**.
3. Sort Weekday Mon→Sun; pick a sequential color ramp.

---

## 6. Sales seasonality + the Nov-2017 Black Friday spike
**Why:** Olist's most famous temporal feature — a sharp **November 2017** spike. Calling it
out shows you read the trend, not just plotted it.
**Data:** `revenue_monthly` (`purchase_month`, `gmv`, `orders`) — already trimmed to complete months.

**Data Studio**
1. **Time series**: dimension `purchase_month`, metric `gmv` (or `orders`).
2. Add a **text box + vertical line shape** annotation at **Nov 2017** labeled "Black Friday"
   (Data Studio has no native date reference line — the shape overlay is the standard workaround).

**Tableau**
1. `purchase_month` (continuous month) → Columns; `gmv` → Rows → line.
2. Add a **Reference Line** at Nov 2017 (Analytics pane → Reference Line → fixed date), label "Black Friday".
   Tableau *does* support date reference lines natively — cleaner than Data Studio here.

---

## 7. Delivery-time distribution (histogram)
**Why:** shows the *shape* — most orders land in ~5–15 days with a long right tail that drives
the bad reviews. Complements the avg-by-bucket chart with the full spread.
**Data:** `fct_orders.delivery_days` (delivered orders).

**Data Studio**
1. Insert → **Histogram** (or Bar with `delivery_days` as dimension), metric **Record Count**.
2. Add a filter `delivery_days IS NOT NULL`; cap the axis (~0–60) so the tail doesn't flatten it.

**Tableau**
1. Drag `delivery_days` to Columns → right-click → **Create → Bins** (size ~3 days).
2. Number of Records → Rows. Filter out Null. Optional: color bars >21 days red (the detractor tail).

---

## 8. Review-score (1–5) distribution
**Why:** the satisfaction *shape* — Olist is famously **U-ish**: lots of 5★, a hard lump of 1★.
A staple, and it frames the whole CX story.
**Data:** `fct_orders.review_score`.

**Data Studio**
1. **Bar chart**: dimension `review_score` (1–5), metric **Record Count**, sort by score asc.
2. Optional: color 1–2★ red, 4–5★ green via conditional formatting on the dimension.

**Tableau**
1. `review_score` (Discrete) → Columns; Number of Records → Rows.
2. Color by `review_score` (red→green diverging); add data labels.

---

## Two more if you want them
- **Worst-rated categories** — `category_performance`: bar of `category` by `avg_review`,
  sorted **ascending**, top 15 → which categories disappoint (pairs with the VoC page).
- **Freight cost by state** — `fct_orders`: dimension `customer_state`, metric `AVG(freight)`
  (or a `freight / gmv` ratio) → shipping-economics geography; overlay on the map from #1.

---

### Which to actually add
For the portfolio, the **Brazil map (#1)**, the **day×hour heatmap (#5)**, and the
**Black-Friday seasonality (#6)** are the highest-impact additions — they're the
"obviously an analyst built this" tiles. The rest are quick wins if you have screen space.
