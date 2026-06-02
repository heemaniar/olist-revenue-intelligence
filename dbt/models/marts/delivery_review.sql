-- THE headline mart: does late delivery drag the review score?
-- One row per delivery-speed bucket, with avg review + detractor share.
select
    case
        when delivery_days <= 3  then '1 · 0-3 days'
        when delivery_days <= 7  then '2 · 4-7 days'
        when delivery_days <= 14 then '3 · 8-14 days'
        when delivery_days <= 21 then '4 · 15-21 days'
        else                          '5 · 22+ days'
    end                                                      as delivery_bucket,
    count(*)                                                 as orders,
    round(avg(review_score), 2)                             as avg_review,
    round(avg(case when review_score <= 2 then 1 else 0 end), 3) as detractor_rate,
    round(avg(case when is_late then 1 else 0 end), 3)      as late_rate
from {{ ref('fct_orders') }}
where delivery_days is not null
  and review_score is not null
group by delivery_bucket
order by delivery_bucket
