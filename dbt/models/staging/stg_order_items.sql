-- Item grain (one row per line item): price + freight, keyed to product & seller.
select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
from {{ source('raw', 'order_items') }}
