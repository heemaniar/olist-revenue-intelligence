-- Delivery metrics — the backbone of the late→satisfaction analysis.
select
    order_id,
    date_diff(date(delivered_customer_at), date(purchase_at), day)            as delivery_days,
    date_diff(date(estimated_delivery_at), date(purchase_at), day)            as promised_days,
    date_diff(date(delivered_customer_at), date(estimated_delivery_at), day)  as delivery_gap_days,
    -- decompose total time: seller handling (purchase→carrier) vs carrier transit (carrier→customer)
    date_diff(date(delivered_carrier_at), date(purchase_at), day)            as handling_days,
    date_diff(date(delivered_customer_at), date(delivered_carrier_at), day)  as transit_days,
    delivered_customer_at > estimated_delivery_at                            as is_late
from {{ ref('stg_orders') }}
where delivered_customer_at is not null
