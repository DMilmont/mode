WITH max_window as (select max("Rolling 7 Day Window") as max_7
                   from fact.d_rolling_seven_days
                  ),

     past_7_days as (
   SELECT dpid,  sum(count)::float  as "Current Week"
 from fact.mode_agg_daily_traffic_and_prospects
    INNER JOIN fact.d_rolling_seven_days ON fact.mode_agg_daily_traffic_and_prospects.date = fact.d_rolling_seven_days.date
    INNER JOIN max_window on 1=1
    WHERE "Rolling 7 Day Window"=max_window.max_7
        and type='Online Express Traffic'
 group by dpid
 ),

 previous_4_weeks as ( -- aggregates 4 weeks before previous week
   SELECT dpid,  sum(count)::float / 4 as "Previous Month - Weekly Average"
 from fact.mode_agg_daily_traffic_and_prospects
    INNER JOIN fact.d_rolling_seven_days ON fact.mode_agg_daily_traffic_and_prospects.date = fact.d_rolling_seven_days.date
    INNER JOIN max_window on 1=1
    WHERE "Rolling 7 Day Window"<max_window.max_7 and "Rolling 7 Day Window">=(max_window.max_7-4)
        and type='Online Express Traffic'
 group by dpid
 )
--Coalesce for dealers with 0 express visits
-- Make sure we are capturing those dealers in our dataset

SELECT 
       to_char(ROW_NUMBER() OVER (ORDER BY ((COALESCE("Current Week", use_if_missing) - "Previous Month - Weekly Average") / (|/"Previous Month - Weekly Average")) asc ), '00')  || ' ' || dp.dpid ||  '</a><br/>' || tabAE.success_manager  "Display String",
       dp.name "Dealer Partner", 
       ROUND("Previous Month - Weekly Average"::numeric, 0) "Previous Month - Weekly Average",
       COALESCE("Current Week", use_if_missing) "Current Week",
       tabAE.success_manager as "Success Manager", 
       tabAE.account_executive AS "Account Executive",
       status,
       tabAE.health_score,
       tabAE.off_weeks_since_launch,
       ROW_NUMBER() OVER (ORDER BY ((COALESCE("Current Week", use_if_missing) - "Previous Month - Weekly Average") / (|/"Previous Month - Weekly Average")) asc ) "Rank",
       ((COALESCE("Current Week", use_if_missing) - "Previous Month - Weekly Average") / (|/"Previous Month - Weekly Average"))::decimal "Importance"
FROM (
    SELECT DISTINCT dpid, name, 0 use_if_missing
    FROM dealer_partners
    WHERE status = 'Live'
         ) dp
LEFT JOIN past_7_days ON dp.dpid = past_7_days.dpid
LEFT JOIN previous_4_weeks ON dp.dpid = previous_4_weeks.dpid
LEFT JOIN fact.salesforce_dealer_info tabAE ON dp.dpid = tabAE.dpid

WHERE ((COALESCE("Current Week", use_if_missing) - "Previous Month - Weekly Average") / (|/"Previous Month - Weekly Average")) >2
  and status = 'Live'
  and off_weeks_since_launch > 6
ORDER BY ((COALESCE("Current Week", use_if_missing) - "Previous Month - Weekly Average") / (|/"Previous Month - Weekly Average")) desc
;