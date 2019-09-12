select COALESCE(segment, 'Not <br> Entered') as segement
      ,sum(count) as count
      ,COALESCE(segment, 'Not <br> Entered')  || '<br> ('|| sum(count) ||')' as label

from fact.zdemo_kpi         
where metric='Shares'
and date>= (date('2019-09-11') - INTERVAL '7 Days')
group by 1
