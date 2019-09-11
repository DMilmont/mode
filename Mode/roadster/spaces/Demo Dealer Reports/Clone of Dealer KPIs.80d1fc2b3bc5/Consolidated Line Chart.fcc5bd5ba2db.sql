select metric as type
      ,date
      ,sum(count)
from report_layer.kpi_past_14days      
where dpid='{{ dpid }}'
group by 1,2
