select metric as type
      ,date
      ,sum(count)
from fact.zdemo_kpi
group by 1,2
