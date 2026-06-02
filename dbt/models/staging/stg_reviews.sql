-- One row per review (raw can have >1 review per order; dedup happens in int_).
select
    review_id,
    order_id,
    review_score,
    review_comment_title            as comment_title,
    review_comment_message          as comment_message,
    length(trim(coalesce(review_comment_message, ''))) >= 15 as has_comment,
    review_creation_date            as review_created_at,
    review_answer_timestamp         as review_answered_at
from {{ source('raw', 'order_reviews') }}
