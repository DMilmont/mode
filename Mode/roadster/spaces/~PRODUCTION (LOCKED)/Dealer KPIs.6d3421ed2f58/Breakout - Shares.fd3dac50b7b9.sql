select COALESCE(segment, 'Not <br> Entered') as segement
      ,sum(count) as count
      ,COALESCE(segment, 'Not <br> Entered')  || '<br> ('|| sum(count) ||')' as label

from report_layer.kpi_past_14days      
where dpid='{{ dpid }}'
and metric='Shares'
and date>= (date_trunc('day', now()) - INTERVAL '7 Days')
group by 1
