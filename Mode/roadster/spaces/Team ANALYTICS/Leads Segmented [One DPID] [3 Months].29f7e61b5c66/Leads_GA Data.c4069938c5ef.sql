with GA_Data as  (select  id
                ,dpid
                ,distinct_id
               ,"timestamp"::date as date
               , channel_grouping
               , medium
              ,source
               , device_category
               , express_landing_page
               , express_referrer
              ,row_number() over ( partition by dpid,distinct_id,"timestamp"::date order by timestamp) as rn
         from ga2_sessions
         where timestamp >='2019-03-01'
         and dpid = '{{ dpid }}'
         ),
lead_types as (
                select dpid
                      ,customer_email
                      ,distinct_id
                      ,min(cohort_date_utc) as cohort_date_utc
                      ,max(agent_first_name) || ' ' || max(agent_last_name) as agent_assigned_lead
                      ,max( case when item_type='UnlockInquiry' then 'UI' end) as "UI"
                      ,max( case when item_type='SharedExpressVehicle' then 'ShEV' end) as "ShEV"
                      ,max( case when item_type='TradeEstimate' then 'TE' end) as "TE"
                      ,max( case when item_type='WelcomeInquiry' then 'WI' end) as "WI"
                      ,max( case when item_type='OrderStarted' then 'OS' end) as "OS"
                      ,max( case when item_type='CreditPreApprovalInquiry' then 'CPAI' end) as "CPAI"
                      ,max( case when item_type='SavedExpressVehicle' then 'SaEV' end) as "SaEV"
                      ,max( case when item_type='MissingVinInquiry' then 'MVI' end) as "MVI"
                      ,max( case when item_type='SATradeStarted' then 'SATS' end) as "SATS"
                      ,max( case when item_type='SoftCreditInquiry' then 'SCI' end) as "SCI"
                      ,max( case when item_type='GeneralInquiry' then 'GI' end) as "GI"
                      ,max( case when item_type='TestDrive' then 'TD' end) as "TD"
                      ,max( case when item_type='VehicleReservation' then 'VR' end) as "VR"
                      ,max( case when item_type='InStorePurchase' then 'ISP' end) as "ISP"
                      ,max( case when item_type='PriceRequest' then 'PR' end) as "PR"
             FROM fact.f_prospect
             where cohort_date_utc >='2019-03-01'
             and dpid = '{{ dpid }}'
             GROUP BY 1,2,3

        )         
         
select p.dpid
      ,p.customer_email
      ,p.agent_assigned_lead
      ,p.distinct_id
      ,p.cohort_date_utc
      ,"UI"
      , "ShEV"
      , "TE"
      ,"WI"
      ,"OS"
      ,"CPAI"
      , "SaEV"
      , "MVI"
      , "SATS"
      , "SCI"
      , "GI"
      , "TD"
      , "VR"
      , "ISP"
      , "PR"
      ,ga.channel_grouping
      ,ga.medium
      ,ga.source
      ,ga.device_category
      ,ga.express_referrer
      ,ga.express_landing_page
from lead_types p
left join (select * from GA_Data where rn=1) ga on p.dpid=ga.dpid and p.distinct_id=ga.distinct_id and p.cohort_date_utc=ga.date
order by cohort_date_utc desc