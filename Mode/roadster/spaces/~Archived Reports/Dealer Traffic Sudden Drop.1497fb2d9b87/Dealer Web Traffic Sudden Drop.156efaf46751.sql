WITH past_day as (  --- List of dealers which had views yesterday
                  SELECT DPID,sum(visitors) as Yday_Visits
                  FROM FACT.agg_daily_dealer_traffic
                  WHERE DATE >= (date_trunc('day', now()) - INTERVAL '1 days')
                  GROUP BY dpid
 ),

 past_week as ( -- Dealers and average count for past week
SELECT DPID,max(visitors) AS Max_Visits
                  FROM FACT.agg_daily_dealer_traffic
                  WHERE DATE >= (date_trunc('day', now()) - INTERVAL '8 days')
                  GROUP BY DPID
 ),

agg_data as (
SELECT dp.dpid as dpid,
       dp.name "Dealer Partner w/ Significant Drop", 
       max_Visits "Max Visits",
       tabAE.success_manager as "Success Manager", 
       tabAE.account_executive AS "Account Executive",
       status,
       tabAE.health_score,
       tabAE.off_weeks_since_launch
FROM (
    SELECT DISTINCT dpid, name, 0 use_if_missing
    FROM dealer_partners
    WHERE status = 'Live'
         ) dp
LEFT JOIN past_day ON dp.dpid = past_day.dpid
LEFT JOIN past_week ON dp.dpid = past_week.dpid
LEFT JOIN fact.salesforce_dealer_info tabAE ON dp.dpid = tabAE.dpid

WHERE past_week.max_visits is not null
  and status = 'Live'
  and off_weeks_since_launch > 6
  and past_week.max_visits>=100 -- No views one day - should have a max daily of 100 views in previous week
  and COALESCE(past_day.Yday_visits,0) <=5 -- dealers which had a drop of 0-5 for web traffic
--
  ),
  
 date_dpid as (
select c.date, dp.dpid, dp.name
from fact.d_cal_date c
cross join (
  select distinct dpid, tableau_secret, name from dealer_partners) dp

LEFT JOIN public.custom_dealer_grouping cdg ON dp.dpid = cdg.dpid
where c.date >= (date_trunc('day', now()) - INTERVAL '61 days')
AND c.date <=  (date_trunc('day',now()) - INTERVAL '1 days')
group by 1,2,3
order by 1 desc
)

SELECT c.date as "Date"
      ,ad.*
      ,coalesce(dt.visitors,0) as "Visitors"
from date_dpid c
left JOIN FACT.agg_daily_dealer_traffic dt ON c.date=dt.date and c.dpid=dt.dpid
inner join  agg_data ad ON  c.dpid=ad.dpid
WHERE c.date >= (date_trunc('day', now()) - INTERVAL '30 days')


