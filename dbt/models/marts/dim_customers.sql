-- Customer grain = customer_unique_id (the real person, NOT per-order customer_id).
-- Repeat-purchase is measured here; expect ~3% in Olist (low-repeat marketplace) —
-- that is the correct number, not a bug.
select
    customer_unique_id,
    count(distinct order_id)                 as orders,
    count(distinct order_id) > 1             as is_repeat,
    round(sum(gmv), 2)                       as lifetime_gmv,
    any_value(customer_state)                as state,
    min(purchase_date)                       as first_order_date,
    max(purchase_date)                       as last_order_date
from {{ ref('fct_orders') }}
where customer_unique_id is not null
group by customer_unique_id
