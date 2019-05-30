WITH raw_data as (

    SELECT fact.f_prospect.*, "7 Day Window", "Rolling 7 Day Window"
    FROM fact.f_prospect
    INNER JOIN fact.d_rolling_seven_days ON fact.f_prospect.cohort_date_utc = fact.d_rolling_seven_days.date
    WHERE fact.f_prospect.cohort_date_utc >= (NOW() - INTERVAL '60 days')
    AND item_type = 'SharedExpressVehicle'
),

 agg_data as (
 SELECT dpid, "Rolling 7 Day Window",
 (SELECT MAX("Rolling 7 Day Window") FROM fact.d_rolling_seven_days) max_rolling,
 COUNT (DISTINCT distinct_id) All_Shares
 FROM raw_data
 GROUP BY dpid, "Rolling 7 Day Window", (SELECT MAX("Rolling 7 Day Window") Max_Window FROM fact.d_rolling_seven_days)
 ),

past_7_days as (
     SELECT dpid, All_Shares "Previous 7 Days Shares"
     FROM agg_data
     WHERE ("Rolling 7 Day Window" - max_rolling) = 0
 ),

 two_weeks_ago as (
     SELECT dpid, All_Shares "7 - 14 Days Shares"
     FROM agg_data
     WHERE ("Rolling 7 Day Window" - max_rolling) = -1
 ),

 previous_6_weeks as (
 SELECT dpid,
        AVG(All_Shares) "Average Shares for 4 Week Period"
 FROM agg_data
 WHERE ("Rolling 7 Day Window" - max_rolling) <= -1 AND ("Rolling 7 Day Window" - max_rolling) > -5
 GROUP BY dpid
 ),

todays_data as (
  SELECT dpid, COUNT(DISTINCT distinct_id) "Today's Share Count"
  FROM raw_data
  WHERE cohort_date_utc = (SELECT MAX(cohort_date_utc) FROM raw_data)
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


--Coalesce for dealers with 0 Shares
-- Make sure we are capturing those dealers in our dataset
final_data as (
SELECT 
       dp.name "Dealer Partner", 
       ROUND("Average Shares for 4 Week Period", 0) "Expected Shares (4Wk Avg)",
       COALESCE("Previous 7 Days Shares", use_if_missing) "Actual Visits (past 7 days)",
       ROUND("Previous 7 Days Shares"/"Average Shares for 4 Week Period",2) "Percentage Change" ,
       CASE 
       WHEN ROUND(((COALESCE("Previous 7 Days Shares", use_if_missing) - "Average Shares for 4 Week Period") / (|/"Average Shares for 4 Week Period"))::decimal, 0) <=-5 THEN '#8a1a23'
       WHEN ROUND(((COALESCE("Previous 7 Days Shares", use_if_missing) - "Average Shares for 4 Week Period") / (|/"Average Shares for 4 Week Period"))::decimal, 0) <=0 THEN '#3e454e'
       ELSE '#27825c' END as "color",
       tabAE.health_score "Health Score",
       ROW_NUMBER() OVER (PARTITION BY tabAE.success_manager ORDER BY ((COALESCE("Previous 7 Days Shares", use_if_missing) - "Average Shares for 4 Week Period") / (|/"Average Shares for 4 Week Period")) asc ) "Rank",
       ROUND(((COALESCE("Previous 7 Days Shares", use_if_missing) - "Average Shares for 4 Week Period") / (|/"Average Shares for 4 Week Period"))::decimal, 0) "Importance"
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

SELECT final_data.*, "Percentage Change"- 1 "Difference from One" 
FROM final_data



