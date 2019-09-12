  select timeframe
  ,sum(count) as count
from fact.zdemo_kpi_visits
group by 1


