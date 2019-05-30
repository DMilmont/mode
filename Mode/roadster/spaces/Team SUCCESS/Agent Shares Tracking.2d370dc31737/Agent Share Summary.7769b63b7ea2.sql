with date_dpid as (
        select DISTINCT date(c.date) as date,dp.id ,dp.dpid, dp.name, primary_make
        from fact.d_cal_date c
               cross join (
          select distinct dps.id,dps.dpid, dps.tableau_secret, dps.name, primary_make
          from dealer_partners dps
          where status = 'Live'
            AND dpid='{{ dpid }}'
        ) dp
             --  where dpid not like '%demo%')dp
        where c.date <= (date_trunc('day', now()) - interval '1 days')
          and CASE WHEN '{{ DateR }}'='Past 7 Days' and  c.date >= (date_trunc('day', now()) - interval '7 days') then 1
                  WHEN  '{{ DateR }}'='Past 30 Days' and  c.date >= (date_trunc('day', now()) - interval '31 days') then 1 
                  WHEN  '{{ DateR }}'='Past 60 Days' and  c.date >= (date_trunc('day', now()) - interval '61 days') then 1 
                  WHEN  '{{ DateR }}'='Past 90 Days' and  c.date >= (date_trunc('day', now()) - interval '91 days') then 1 
                  ELSE 0 END = 1
        group by 1, 2, 3, 4, 5
      ),
     agent as (
       select first_name||' ' ||substr(last_name,1,1) as agent_name
              ,a.*
       from agents a
       where  status='Active'
     ),
    leads_submitted as (
      select *
      from lead_submitted
      where timestamp >= (date_trunc('day', now()) - interval '91 days')
        and type='SharedExpressVehicle'
        and sent_at is not null
    ),
    detail as (SELECT dd.date
                    , dd.dpid
                    , dd.name
                    ,a.agent_name
                    ,a.job_title
                    , ls.id
                    ,ls.crm_record_id
                    ,ls.vin
                    ,ls.make
                    ,ls.model
                    ,ls.year
                    ,ls.grade
                    ,ls.deal_type
                    ,ls.referral_coupon
                    ,ls.details
                    ,ls.order_id
                    ,case when ls.delivered_at is not null
                          then 1 else 0 end as Deliver_Check
                    ,case when ls.clicked_at is not  null or ls.opened_at is not null
                          then 1 else 0 end as Open_Check
                   ,case when ls.clicked_at is not null
                          then 1 else 0 end as Click_Check
               FROM date_dpid dd
                      left join leads_submitted ls on dd.id = ls.dealer_partner_id and date(dd.date) = date(ls.sent_at)
                      left join agent a on ls.agent_id=a.id
    )
select date
      ,dpid
      ,name
     ,COUNT(distinct id) as agent_shares
      ,sum(Deliver_Check) as shares_delivered
      ,CASE when sum(Deliver_Check) =0 then 0 else round(sum(Deliver_Check)::decimal/count(distinct id),2) END as shares_delivered_perc
      ,sum(Open_Check) as shares_opened
      ,CASE when sum(Open_Check) =0 then 0 else round(sum(Open_Check)::decimal/count(distinct id),2) END as shares_opened_perc
      ,sum(Click_Check)  as shares_clicked
      ,CASE when sum(Click_Check) =0 then 0 else round(sum(Click_Check)::decimal/count(distinct id),2) END as shares_clicked_perc
from detail
GROUP BY 1,2,3

{% form %}

DateR:
    type: select
    default: "Past 7 Days"
    label: Date Range
    options: ["Past 7 Days", "Past 30 Days","Past 60 Days","Past 90 Days"]
    
{% endform %}