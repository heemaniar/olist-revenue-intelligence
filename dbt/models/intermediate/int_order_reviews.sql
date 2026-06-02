-- One review per order (raw can have >1); keep the latest by creation date.
select
    order_id,
    review_id,
    review_score,
    comment_message,
    has_comment
from (
    select
        *,
        row_number() over (
            partition by order_id order by review_created_at desc
        ) as rn
    from {{ ref('stg_reviews') }}
)
where rn = 1
