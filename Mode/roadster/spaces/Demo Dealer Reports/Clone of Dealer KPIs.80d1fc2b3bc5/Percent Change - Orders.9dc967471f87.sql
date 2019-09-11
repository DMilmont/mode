with output as (

select  case when date>= (date_trunc('day', now()) - INTERVAL '7 Days')  then 'Current 7 Days'
            when date>= (date_trunc('day', now()) - INTERVAL '14 Days') then 'Past 7 Days' end as timeframe
      ,sum(count) as count

from report_layer.kpi_past_14days      
where dpid='{{ dpid }}'
and metric='Orders'
and date>= (date_trunc('day', now()) - INTERVAL '14 Days')
group by 1

)

select * from output
union 
select 'Current 7 Days', 0
where case when 'Current 7 Days' in (select timeframe from output) then 0 else 1 end =1
union
select 'Past 7 Days', 0
where case when 'Past 7 Days' in (select timeframe from output) then 0 else 1 end =1