WITH raw_data as (

    SELECT fact.f_traffic.*, "7 Day Window", "Rolling 7 Day Window"
    FROM fact.f_traffic
    INNER JOIN fact.d_rolling_seven_days ON fact.f_traffic.date = fact.d_rolling_seven_days.date
    WHERE fact.f_traffic.date >= (NOW() - INTERVAL '60 days')
    AND is_in_store = False

),

 agg_data as (
 SELECT dpid, "Rolling 7 Day Window",
 (SELECT MAX("Rolling 7 Day Window") FROM fact.d_rolling_seven_days) max_rolling,
 COUNT (DISTINCT distinct_id) Online_Express_Visitors
 FROM raw_data
 GROUP BY dpid, "Rolling 7 Day Window", (SELECT MAX("Rolling 7 Day Window") Max_Window FROM fact.d_rolling_seven_days)
 ),

past_7_days as (
     SELECT dpid, Online_Express_Visitors "Previous 7 Days Express Visits"
     FROM agg_data
     WHERE ("Rolling 7 Day Window" - max_rolling) = 0
 ),

 previous_4_weeks as (
 SELECT dpid,
        AVG(Online_Express_Visitors) "Average Express Visits for 4 Week Period"
 FROM agg_data
 WHERE ("Rolling 7 Day Window" - max_rolling) < -1 AND ("Rolling 7 Day Window" - max_rolling) > -7
 GROUP BY dpid
 )


--Coalesce for dealers with 0 express visits
-- Make sure we are capturing those dealers in our dataset

SELECT 
       to_char(ROW_NUMBER() OVER (ORDER BY ((COALESCE("Previous 7 Days Express Visits", use_if_missing) - "Average Express Visits for 4 Week Period") / (|/"Average Express Visits for 4 Week Period")) desc), '00')  || ' ' || dp.name || ' (' || tabAE.success_manager || ')' "Display String",
       dp.name "Dealer Partner", 
       ROUND("Average Express Visits for 4 Week Period", 0) "Expected Express Visitors (4Wk Avg)",
       COALESCE("Previous 7 Days Express Visits", use_if_missing) "Actual Visits (past 7 days)",
       tabAE.success_manager as "Success Manager", 
       tabAE.account_executive AS "Account Executive",
       tabAE.health_score,
       tabAE.off_weeks_since_launch,
       status,
       ROW_NUMBER() OVER (ORDER BY ((COALESCE("Previous 7 Days Express Visits", use_if_missing) - "Average Express Visits for 4 Week Period") / (|/"Average Express Visits for 4 Week Period")) desc ) "Rank",
       ROUND(((COALESCE("Previous 7 Days Express Visits", use_if_missing) - "Average Express Visits for 4 Week Period") / (|/"Average Express Visits for 4 Week Period"))::decimal, 0) "Importance"
FROM (
    SELECT DISTINCT dpid, name, 0 use_if_missing
    FROM dealer_partners
    WHERE status = 'Live'
         ) dp
LEFT JOIN past_7_days ON dp.dpid = past_7_days.dpid
LEFT JOIN previous_4_weeks ON dp.dpid = previous_4_weeks.dpid
LEFT JOIN fact.salesforce_dealer_info tabAE ON dp.dpid = tabAE.dpid

WHERE ((COALESCE("Previous 7 Days Express Visits", use_if_missing) - "Average Express Visits for 4 Week Period") / (|/"Average Express Visits for 4 Week Period")) >2
  and status = 'Live'
  and off_weeks_since_launch > 6
ORDER BY ((COALESCE("Previous 7 Days Express Visits", use_if_missing) - "Average Express Visits for 4 Week Period") / (|/"Average Express Visits for 4 Week Period")) desc 
;
