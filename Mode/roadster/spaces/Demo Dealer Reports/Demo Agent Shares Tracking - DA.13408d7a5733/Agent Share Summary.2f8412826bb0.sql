
select date
      ,dpid
      ,name
     ,COUNT(distinct id) as "Agent Shares"
      ,sum(Deliver_Check) as "Shares Delivered"
      ,CASE when sum(Deliver_Check) =0 then 0 else round(sum(Deliver_Check)::decimal/count(distinct id),2) END as "Shares Delivered %"
      ,sum(Open_Check) as "Shares Opened"
      ,CASE when sum(Open_Check) =0 then 0 else round(sum(Open_Check)::decimal/count(distinct id),2) END as "Shares Opened %"
      ,sum(Click_Check)  as "Shares Clicked"
      ,CASE when sum(Click_Check) =0 then 0 else round(sum(Click_Check)::decimal/count(distinct id),2) END as "Shares Clicked %"
from fact.zdemo_shares_detail
where date >= (date_trunc('day', now()) - interval '31 days')  
    and dpid='{{ dpid }}'
GROUP BY 1,2,3

