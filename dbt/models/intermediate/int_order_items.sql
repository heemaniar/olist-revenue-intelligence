-- Collapse the item fan-out to ONE row per order before joining to orders,
-- so GMV is not double-counted. GMV = item price (excludes freight).
select
    order_id,
    count(*)                                 as n_items,
    count(distinct seller_id)                as n_sellers,
    count(distinct product_id)               as n_products,
    round(sum(price), 2)                     as gmv,
    round(sum(freight_value), 2)             as freight,
    round(sum(price + freight_value), 2)     as items_total
from {{ ref('stg_order_items') }}
group by order_id
