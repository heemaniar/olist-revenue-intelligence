---
title: Olist Revenue & CX Intelligence
---

Marketplace revenue & customer-experience analytics on the real **Olist** Brazilian
e-commerce dataset (~99k orders, 2017–2018). Built as code with **Evidence** on the
governed dbt marts. _Real public data — © Olist, CC BY-NC-SA 4.0, non-commercial demo._

```sql kpis
select
  sum(gmv)                                   as gmv,
  sum(net_revenue)                           as net_revenue,
  count(distinct order_id)                   as orders,
  sum(gmv) / count(distinct order_id)        as aov,
  avg(case when cast(is_late as varchar) ilike 'true'  then 0.0
           when cast(is_late as varchar) ilike 'false' then 1.0 end) as on_time_rate,
  avg(review_score)                          as avg_review
from olist.fct_orders
```

```sql repeat
with c as (
  select customer_unique_id, count(distinct order_id) as n
  from olist.fct_orders group by 1
)
select avg(case when n > 1 then 1.0 else 0.0 end) as repeat_rate from c
```

<BigValue data={kpis} value=gmv fmt=usd0 title="GMV"/>
<BigValue data={kpis} value=orders fmt=num0 title="Orders"/>
<BigValue data={kpis} value=aov fmt=usd2 title="AOV"/>
<BigValue data={kpis} value=on_time_rate fmt=pct1 title="On-Time %"/>
<BigValue data={kpis} value=avg_review fmt=num2 title="Avg Review"/>
<BigValue data={repeat} value=repeat_rate fmt=pct1 title="Repeat %"/>

**Repeat purchase is just ~3%** — Olist is acquisition-rich but retention-poor. That's
the central growth gap, not a footnote.

## Revenue over time

```sql gmv_monthly
select purchase_month, gmv, orders
from olist.revenue_monthly
order by purchase_month
```

<LineChart data={gmv_monthly} x=purchase_month y=gmv yFmt=usd0 title="Monthly GMV — complete months only"/>

The series is trimmed to Olist's usable window (2017-01 … 2018-08) **in the dbt model**,
so the trend is correct by default — no dashboard-level filtering. Note the **Nov-2017
Black Friday** spike.
