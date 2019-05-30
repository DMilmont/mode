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

 two_weeks_ago as (
     SELECT dpid, Online_Express_Visitors "7 - 14 Days Express Visits"
     FROM agg_data
     WHERE ("Rolling 7 Day Window" - max_rolling) = -1
 ),

 previous_6_weeks as (
 SELECT dpid,
        AVG(Online_Express_Visitors) "Average Express Visits for 4 Week Period"
 FROM agg_data
 WHERE ("Rolling 7 Day Window" - max_rolling) <= -1 AND ("Rolling 7 Day Window" - max_rolling) > -5
 GROUP BY dpid
 ),

todays_data as (
  SELECT dpid, COUNT(DISTINCT distinct_id) "Today's Express Visitor Count"
  FROM raw_data
  WHERE date = (SELECT MAX(date) FROM raw_data)
  GROUP BY dpid
),

filter_for_dpids as (
  -- Generate the Dealer Group associated with the dpid param filter
  -- Sets up the entire query. Needs the dpsk and the dpid from params to work
  SELECT DISTINCT di.dealer_group
  FROM fact.salesforce_dealer_info di
  INNER JOIN public.dealer_partners dp on di.dpid = dp.dpid
  WHERE di.dpid = '{{ dpid }}' AND dp.tableau_secret = {{ dpsk }}
),

filter_for_dealer_group  as (
SELECT DISTINCT di.dpid
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE dealer_group = (SELECT * FROM filter_for_dpids)
),


--Coalesce for dealers with 0 express visits
-- Make sure we are capturing those dealers in our dataset
final_data as (
SELECT 
       dp.name "Dealer Partner", 
       ROUND("Average Express Visits for 4 Week Period", 0) "Expected Express Visitors (4Wk Avg)",
       COALESCE("Previous 7 Days Express Visits", use_if_missing) "Actual Visits (past 7 days)",
       ROUND("Previous 7 Days Express Visits"/"Average Express Visits for 4 Week Period",2) "Percentage Change" ,
       CASE 
       WHEN ROUND(((COALESCE("Previous 7 Days Express Visits", use_if_missing) - "Average Express Visits for 4 Week Period") / (|/"Average Express Visits for 4 Week Period"))::decimal, 0) <=-5 THEN '#8a1a23'
       WHEN ROUND(((COALESCE("Previous 7 Days Express Visits", use_if_missing) - "Average Express Visits for 4 Week Period") / (|/"Average Express Visits for 4 Week Period"))::decimal, 0) <=0 THEN '#3e454e'
       ELSE '#27825c' END as "color",
       tabAE.health_score "Health Score",
       ROW_NUMBER() OVER (PARTITION BY tabAE.success_manager ORDER BY ((COALESCE("Previous 7 Days Express Visits", use_if_missing) - "Average Express Visits for 4 Week Period") / (|/"Average Express Visits for 4 Week Period")) asc ) "Rank",
       ROUND(((COALESCE("Previous 7 Days Express Visits", use_if_missing) - "Average Express Visits for 4 Week Period") / (|/"Average Express Visits for 4 Week Period"))::decimal, 0) "Importance"
FROM (
    SELECT DISTINCT dpid, name, 0 use_if_missing
    FROM dealer_partners
    WHERE status = 'Live'
         ) dp
LEFT JOIN todays_data ON dp.dpid = todays_data.dpid
LEFT JOIN past_7_days ON dp.dpid = past_7_days.dpid
LEFT JOIN two_weeks_ago ON dp.dpid = two_weeks_ago.dpid
LEFT JOIN previous_6_weeks ON dp.dpid = previous_6_weeks.dpid
LEFT JOIN fact.salesforce_dealer_info tabAE ON dp.dpid = tabAE.dpid
WHERE status = 'Live'
  and off_weeks_since_launch > 6
  and dp.dpid IN (SELECT * FROM filter_for_dealer_group)
  )
  
SELECT final_data.*, "Percentage Change" - 1 "Difference from One"
FROM final_data
