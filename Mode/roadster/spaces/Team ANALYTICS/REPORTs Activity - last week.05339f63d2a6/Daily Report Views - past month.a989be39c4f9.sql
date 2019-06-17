-- This report accesses the following tables - PLEASE KEEP THIS UPDATED --
-- public.ga2_pageviews
-- fact.salesforce_dealer_info
-- ga_pageviews

WITH 
    GA AS ( SELECT ga2_pageviews.id,
            (ga2_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone DealerTime,
              ga2_pageviews.page_path,
              gs.landing_page_path,
              ga2_pageviews.property,
              gs.dpid,
              ga2_pageviews.distinct_id,
              gs.in_store,
              a.email, 
              gs.full_referrer,
          1 count
   
   FROM ga2_pageviews
   
-- Join dealer_partners to get the Time zone
-- Filter down to only Dealer Admin pages, and only the past 7 days
   LEFT JOIN 
   (
   SELECT *
   FROM public.ga2_sessions
   WHERE agent_dbid ~ '^[0-9]*$'
   AND timestamp > (date_trunc('day' :: text, now()) - '7 days' :: interval)
   )
   gs ON ga2_pageviews.ga2_session_id = gs.id
   LEFT JOIN public.dealer_partners dp ON gs.dpid = dp.dpid
   LEFT JOIN agents a ON (gs.agent_dbid)::integer = a.user_dbid
   WHERE Property = 'Dealer Admin'
     AND ((ga2_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME
          ZONE dp.timezone) > (date_trunc('day' :: text, now()) - '7 days' :: interval)
     AND ((ga2_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME
          ZONE dp.timezone) < (date_trunc('day' :: text, now())) 
     AND dp.status = 'Live'
     ),
   
   
     GAday AS (SELECT 
          Property,
          btrim(regexp_replace(regexp_replace((GA.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)) AS page_path_fixed,
          dpid,
          email agent_email,
          date_part('day', DealerTime) day_t,
          date_part('month', DealerTime) month_t,
          date_part('year', DealerTime) year_t,
          count(*) AS daily_views
   FROM ga
   WHERE ((GA.page_path) :: text ~~* '%/reports/%' :: text)
   GROUP BY Property,
            btrim(regexp_replace(regexp_replace((GA.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)),
            date_part('day', DealerTime),
            date_part('month', DealerTime),
            date_part('year', DealerTime),
            dpid,
            agent_email
                )
            
SELECT 
       to_date(LPAD(day_t::text, 2, '0') || LPAD(month_t::text, 2, '0') || year_t::text, 'DDMMYYYY') "Date",
       sum(GAday.daily_views) AS "Report Views",
       
       CASE
           WHEN agent_email ~* '@roadster.com\M' then '.Roadster Users'
           ELSE 'Customers'
       END AS "User Type"
FROM GAday
LEFT JOIN fact.salesforce_dealer_info sf
  ON GAday.dpid = sf.dpid
  
   where sf.status = 'Live'
  Group By "Date", "User Type"

  ORDER BY "Report Views" desc;