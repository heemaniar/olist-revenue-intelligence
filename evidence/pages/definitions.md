---
title: Metric Definitions
sidebar_position: 4
---

The KPI **single source of truth**. Every number on this dashboard, in the dbt marts,
and in `METRICS.md` uses these exact definitions — loaded from the warehouse
`metric_definitions` table, not living in someone's head.

```sql defs
select kpi, definition, calculation, population, target, owner
from olist.metric_definitions
```

<DataTable data={defs} rows=20>
  <Column id=kpi title="KPI"/>
  <Column id=definition wrap=true/>
  <Column id=calculation wrap=true/>
  <Column id=population/>
  <Column id=target/>
  <Column id=owner/>
</DataTable>
