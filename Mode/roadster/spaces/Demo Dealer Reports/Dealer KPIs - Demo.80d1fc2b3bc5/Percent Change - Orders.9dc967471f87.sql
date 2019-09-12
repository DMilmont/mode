with output as (

select  case when date>= (date('2019-09-11')  - INTERVAL '7 Days')  then 'Current 7 Days'
            when date>= (date('2019-09-11')  - INTERVAL '14 Days') then 'Past 7 Days' end as timeframe
      ,sum(count) as count

from fact.zdemo_kpi        
where metric='Orders'
and date>= (date('2019-09-11') - INTERVAL '14 Days')
group by 1

)

select * from output
union 
select 'Current 7 Days', 0
where case when 'Current 7 Days' in (select timeframe from output) then 0 else 1 end =1
union
select 'Past 7 Days', 0
where case when 'Past 7 Days' in (select timeframe from output) then 0 else 1 end =1