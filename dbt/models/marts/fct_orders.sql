-- Order spine: one row per order, joined to the four int_ aggregates + customer.
-- This is the grain the Data Studio dashboard sits on.
with o as (select * from {{ ref('stg_orders') }})

select
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.state                                  as customer_state,
    o.order_status,
    -- counts toward revenue? (status filter, var-driven)
    o.order_status in (
        {%- for s in var('valid_order_status') -%}
        '{{ s }}'{{ "," if not loop.last }}
        {%- endfor -%}
    )                                        as is_valid_revenue,
    o.purchase_at,
    date(o.purchase_at)                      as purchase_date,
    date_trunc(date(o.purchase_at), month)   as purchase_month,
    o.delivered_customer_at                  as delivered_at,
    o.estimated_delivery_at                  as estimated_at,
    coalesce(i.gmv, 0)                        as gmv,
    coalesce(i.freight, 0)                    as freight,
    coalesce(i.gmv, 0) + coalesce(i.freight, 0) as net_revenue,
    i.n_items,
    i.n_sellers,
    i.n_products,
    p.paid_value,
    p.max_installments,
    p.primary_payment_type,
    d.delivery_days,
    d.promised_days,
    d.delivery_gap_days,
    d.is_late,
    r.review_score,
    r.has_comment
from o
left join {{ ref('int_order_items') }}    i using (order_id)
left join {{ ref('int_order_payments') }} p using (order_id)
left join {{ ref('int_order_delivery') }} d using (order_id)
left join {{ ref('int_order_reviews') }}  r using (order_id)
left join {{ ref('stg_customers') }}      c on c.customer_id = o.customer_id
