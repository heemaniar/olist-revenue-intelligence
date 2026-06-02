-- Item grain, enriched for product/seller/category analysis.
select
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    i.price,
    i.freight_value,
    pr.category,
    s.state                  as seller_state,
    o.purchase_month,
    o.is_valid_revenue,
    o.is_late,
    o.review_score
from {{ ref('stg_order_items') }} i
left join {{ ref('stg_products') }} pr using (product_id)
left join {{ ref('stg_sellers') }}  s  using (seller_id)
left join {{ ref('fct_orders') }}   o  using (order_id)
