---
title: Voice of Customer (AI)
---

Portuguese review comments tagged by **Claude** (structured output: sentiment +
themes + English summary). The model separates *frequency* from *severity* in a way
star ratings alone can't.

```sql coverage
select count(distinct review_id) as reviews from olist.review_themes
```

<BigValue data={coverage} value=reviews fmt=num0 title="AI-tagged reviews (sample)"/>

## What hurts satisfaction most — by theme

```sql theme_score
select theme,
       avg(review_score)        as avg_review,
       count(distinct review_id) as reviews
from olist.review_themes
group by theme
order by avg_review asc
```

<BarChart data={theme_score} x=theme y=avg_review swapXY=true title="Avg review score by theme (ascending = pain points)" yFmt=num2 sort=false/>

**Delivery** is the most *frequent* complaint, but **wrong/missing item (~1.7★)** and
**not-as-described (~2.5★)** are the most *severe* — fulfillment-accuracy problems that
score lower than slow delivery. Different owners (sellers/fulfillment vs carrier).

## Theme volume by sentiment

```sql theme_sentiment
select theme, sentiment, count(distinct review_id) as reviews
from olist.review_themes
group by theme, sentiment
order by reviews desc
```

<BarChart data={theme_sentiment} x=theme y=reviews series=sentiment type=stacked title="Reviews by theme and sentiment" swapXY=true/>

## Sample negative comments (Claude summaries)

```sql complaints
select theme, summary_en, review_score
from olist.review_themes
where sentiment = 'negative'
order by review_score asc
limit 40
```

<DataTable data={complaints} rows=12 search=true/>
