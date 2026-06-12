---
title: Sellers & Categories
sidebar_position: 2
---

## Revenue is seller-concentrated

```sql concentration
select round(100.0 * sum(case when gmv_pct_rank <= 0.10 then gmv else 0 end) / sum(gmv), 1) as top10_share
from (
  select gmv, percent_rank() over (order by gmv desc) as gmv_pct_rank
  from olist.seller_performance
)
```

<BigValue data={concentration} value=top10_share fmt=num1 title="% of GMV from the top 10% of sellers"/>

```sql top_sellers
select seller_id, gmv, gmv_cumulative_share
from olist.seller_performance
order by gmv desc
limit 20
```

<BarChart data={top_sellers} x=seller_id y=gmv title="Top 20 sellers by GMV" yFmt=usd0 sort=false/>

<DataTable data={top_sellers} rows=10>
  <Column id=seller_id/>
  <Column id=gmv fmt=usd0/>
  <Column id=gmv_cumulative_share fmt=pct1 title="Cumulative GMV share"/>
</DataTable>

## Category revenue vs satisfaction

```sql cats
select category, gmv, avg_review, orders, freight_to_price
from olist.category_performance
order by gmv desc
```

<BubbleChart data={cats} x=gmv y=avg_review size=orders series=category xFmt=usd0 yFmt=num2 title="Category: GMV (x) vs avg review (y), size = orders" legend=false/>

Big bubbles low on the Y axis = high-revenue, low-satisfaction categories to fix.

## Worst-rated categories

```sql worst_cats
select category, avg_review, orders
from olist.category_performance
order by avg_review asc
limit 15
```

<BarChart data={worst_cats} x=category y=avg_review swapXY=true title="Lowest average review by category" yFmt=num2 sort=false/>
