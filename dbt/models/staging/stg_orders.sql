-- One row per order: status + the four lifecycle timestamps, renamed to *_at.
select
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp        as purchase_at,
    order_approved_at               as approved_at,
    order_delivered_carrier_date    as delivered_carrier_at,
    order_delivered_customer_date   as delivered_customer_at,
    order_estimated_delivery_date   as estimated_delivery_at
from {{ source('raw', 'orders') }}
