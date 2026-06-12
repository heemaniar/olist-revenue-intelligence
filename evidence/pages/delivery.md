---
title: Delivery & Satisfaction
---

The headline CX story: **late delivery is the #1 satisfaction killer — and it's a
carrier problem, not seller dispatch.**

## Review score by delivery time

```sql by_bucket
select delivery_bucket, avg_review, late_rate
from olist.delivery_review
order by avg_review desc
```

<BarChart data={by_bucket} x=delivery_bucket y=avg_review swapXY=true title="Avg review by delivery-days bucket" yFmt=num2/>

Satisfaction falls steadily as delivery slows.

## Where does lateness come from? Handling vs carrier transit

```sql decomp
select delivery_status, 'handling (seller)' as stage, avg_handling_days as days from olist.delivery_stages
union all
select delivery_status, 'transit (carrier)' as stage, avg_transit_days as days from olist.delivery_stages
```

<BarChart data={decomp} x=delivery_status y=days series=stage type=grouped title="Delivery decomposition (days)"/>

When orders go **late**, carrier **transit balloons (~26 vs 8 days)** while seller
**handling barely moves (~6 vs 3)**. The fix is carrier SLAs / regional carriers — not
seller onboarding.

## Distance drives delivery time and satisfaction

```sql distance
select distance_band, avg_delivery_days, avg_review, late_rate
from olist.distance_delivery
order by band_order
```

<BarChart data={distance} x=distance_band y=avg_delivery_days title="Avg delivery days by customer↔seller distance" yFmt=num1/>

Near orders (0–50 km) deliver in ~6 days at 4.28★; 1,000+ km orders take ~19 days at
4.02★ — the distance → delivery → review chain.

## On-time rate by state

```sql by_state
select state, on_time_rate, orders
from olist.state_performance
order by on_time_rate desc
```

<BarChart data={by_state} x=state y=on_time_rate swapXY=true title="On-time delivery rate by state" yFmt=pct1/>
