

WITH 
    GA AS ( SELECT 
            gas.dpid,
            (gap."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone "dealertime",
            gap.property,
            gap.page_path,
            gap.distinct_id,
            1 count
   FROM ga2_pageviews gap
   left join public.ga2_sessions gas on gas.id = gap.ga2_session_id
   left join public.dealer_partners dp on gas.dpid = dp.dpid
   WHERE property = 'Dealer Admin')
   
   
  ,GA_wk AS (SELECT 
          GA.dpid,
          date_trunc('week',dealertime)::date "week",
          --btrim(regexp_replace(regexp_replace((GA.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)) AS report,
          count(1) as "report views"
   FROM GA
   left join fact.salesforce_dealer_info sf on sf.dpid = GA.dpid
   WHERE ((GA.page_path) :: text ~~* '%/reports/%' :: text)
   and sf.status is not null
   and dealertime is not null 
   GROUP BY 1,2)


   ,shares as (SELECT 
          date_trunc('week', cohort_date_utc - 1 )::date "week", -- Note: I pushed the days back so weeks are Sun>Sat... I did this because this report is sent out on Mondays and Sunday data is never ready in time.  
          dpid,
          count(distinct f_prospect.customer_email) "shares"
    FROM fact.f_prospect
    WHERE item_type = 'SharedExpressVehicle'
    AND source = 'Lead Type'
    and cohort_date_utc > '03/04/2019'::date
    GROUP BY 1,2
    )
  
  ,dealers_sharing as(SELECT
        week,
        count(distinct dpid) "active_dealers"
      from shares 
      where shares > 1
      group by 1
        )

    ,dealers_reporting as (select 
        week,
        count(case when "report views" >= 2 then 1 else null end) as "reporting_dealers_min2"
      from  GA_wk
      group by 1)
      

      
      select ds.week, active_dealers, "reporting_dealers_min2",
          round(reporting_dealers_min2::decimal/active_dealers::decimal*100,1) as "% DPIDs viewing at least 2 Reports",
          65 as "Goal"
      from dealers_sharing ds
      left join dealers_reporting dr on dr.week = ds.week
      where reporting_dealers_min2 > 0