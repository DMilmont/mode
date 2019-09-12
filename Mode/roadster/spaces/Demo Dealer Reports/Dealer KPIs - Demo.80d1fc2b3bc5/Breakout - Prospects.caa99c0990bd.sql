select segment
      ,sum(count) as count
      ,segment  || '<br> ('|| sum(count) ||')' as label

from fact.zdemo_kpi       
where metric='Prospects'
and date>= (date('2019-09-11') - INTERVAL '7 Days')
group by 1
