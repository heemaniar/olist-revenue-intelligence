-- Per seller: GMV, orders, satisfaction, late rate, and GMV share (for the Pareto).
with base as (
    select
        seller_id,
        seller_state,
        count(distinct order_id)                            as orders,
        round(sum(price), 2)                                as gmv,
        round(avg(review_score), 2)                         as avg_review,
        round(avg(case when is_late is true then 1
                       when is_late is false then 0 end), 3) as late_rate
    from {{ ref('fct_order_items') }}
    where is_valid_revenue
    group by seller_id, seller_state
)
select
    *,
    round(gmv / sum(gmv) over (), 4)                        as gmv_share,
    round(sum(gmv) over (order by gmv desc) / sum(gmv) over (), 4) as gmv_cumulative_share
from base
