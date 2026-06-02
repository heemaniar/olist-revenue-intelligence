-- Collapse the payment fan-out to one row per order.
with agg as (
    select
        order_id,
        round(sum(payment_value), 2)    as paid_value,
        max(payment_installments)       as max_installments,
        count(*)                         as n_payments
    from {{ ref('stg_payments') }}
    group by order_id
),

-- primary_payment_type = type of the largest single payment on the order
primary_type as (
    select order_id, payment_type as primary_payment_type
    from (
        select
            order_id, payment_type,
            row_number() over (
                partition by order_id order by payment_value desc
            ) as rn
        from {{ ref('stg_payments') }}
    )
    where rn = 1
)

select
    agg.order_id,
    agg.paid_value,
    agg.max_installments,
    agg.n_payments,
    primary_type.primary_payment_type
from agg
left join primary_type using (order_id)
