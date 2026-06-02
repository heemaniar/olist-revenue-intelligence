-- Singular test: order-grain GMV must equal raw item-grain revenue.
-- Proves the fan-out aggregation in int_order_items neither dropped nor
-- double-counted revenue. Passes when it returns 0 rows.
with modeled as (
    select round(sum(gmv), 2) as g from {{ ref('fct_orders') }}
),
raw_items as (
    select round(sum(price), 2) as g from {{ ref('stg_order_items') }}
)
select
    modeled.g  as modeled_gmv,
    raw_items.g as raw_gmv
from modeled
cross join raw_items
where abs(modeled.g - raw_items.g) > 1   -- 1 BRL tolerance for rounding
