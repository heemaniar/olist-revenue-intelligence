-- Delivery decomposition: seller handling (purchase→carrier) vs carrier transit
-- (carrier→customer), split by on-time/late. Answers "is lateness a seller-dispatch
-- problem or a carrier problem?" — the precision my decision brief was missing.
select
    if(is_late, 'Late', 'On-time')   as delivery_status,
    count(*)                          as orders,
    round(avg(delivery_days), 1)      as avg_delivery_days,
    round(avg(handling_days), 1)      as avg_handling_days,   -- seller dispatch
    round(avg(transit_days), 1)       as avg_transit_days     -- carrier
from {{ ref('fct_orders') }}
where delivered_at is not null
  and is_late is not null
  and handling_days is not null
  and transit_days is not null
group by delivery_status
