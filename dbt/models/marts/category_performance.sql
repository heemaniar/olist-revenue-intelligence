-- Per product category: GMV, satisfaction, freight burden, late rate.
select
    category,
    count(distinct order_id)                                as orders,
    round(sum(price), 2)                                    as gmv,
    round(avg(review_score), 2)                             as avg_review,
    round(safe_divide(sum(freight_value), sum(price)), 3)   as freight_to_price,
    round(avg(case when is_late is true then 1
                   when is_late is false then 0 end), 3)    as late_rate
from {{ ref('fct_order_items') }}
where is_valid_revenue
group by category
