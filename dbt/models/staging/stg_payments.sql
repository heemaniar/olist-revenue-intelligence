-- Payment grain (an order can have several rows); collapsed in int_order_payments.
select
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
from {{ source('raw', 'order_payments') }}
