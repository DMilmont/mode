select segment
      ,sum(count) as count
      ,segment  || '<br> ('|| sum(count) ||')' as label

from report_layer.kpi_past_14days      
where dpid='{{ dpid }}'
and metric='Orders'
and date>= (date_trunc('day', now()) - INTERVAL '7 Days')
group by 1
