-- This report accesses the following tables - PLEASE KEEP THIS UPDATED --
-- public.ga2_pageviews
-- fact.salesforce_dealer_info
-- ga_pageviews



SELECT *
FROM public.ga_pageviews;

WITH 
    GA AS (SELECT 
        ga_pageviews.id,
        ga_pageviews.count, (GA_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone DealerTime,
        ga_pageviews.page_path,
        ga_pageviews.landing_page_path,
        ga_pageviews.property,
        ga_pageviews.dpid,
        ga_pageviews.distinct_id,
        ga_pageviews.in_store,
        ga_pageviews.agent_id,
        ga_pageviews.agent_email,
        ga_pageviews.full_referrer
   FROM ga_pageviews
   LEFT JOIN public.dealer_partners dp
     ON ga_pageviews.dpid = dp.dpid
   
   WHERE Property = 'Dealer Admin'
     AND ((ga_pageviews."timestamp" AT TIME
           ZONE 'UTC') AT TIME
          ZONE dp.timezone) > (date_trunc('day' :: text, now()) - '31 days' :: interval)
     AND ((ga_pageviews."timestamp" AT TIME
           ZONE 'UTC') AT TIME
          ZONE dp.timezone) < (date_trunc('day' :: text, now())) 
          ),
   
   
     GAday AS (SELECT 
          Property,
          btrim(regexp_replace(regexp_replace((GA.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)) AS page_path_fixed,
          dpid,
          agent_email,
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