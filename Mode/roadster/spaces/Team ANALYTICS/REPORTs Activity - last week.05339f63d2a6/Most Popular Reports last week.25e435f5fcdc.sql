-- This report accesses the following tables - PLEASE KEEP THIS UPDATED --
-- public.ga2_pageviews
-- ga_pageviews
-- fact.salesforce_dealer_info

SELECT *
FROM public.ga2_pageviews;

WITH GA AS
  (SELECT ga_pageviews.id,
          ga_pageviews.count, (GA_pageviews."timestamp" AT TIME
                             ZONE 'UTC') AT TIME
   ZONE dp.timezone DealerTime,
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
          ZONE dp.timezone) > (date_trunc('day' :: text, now()) - '7 days' :: interval)
     AND ((ga_pageviews."timestamp" AT TIME
           ZONE 'UTC') AT TIME
          ZONE dp.timezone) < (date_trunc('day' :: text, now())) ),
     GAday AS
  (SELECT Property,
          left(btrim(regexp_replace(regexp_replace((GA.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)),25) AS page_path_fixed,
          dpid,
          agent_email,
          date_part('day', DealerTime) day_t,
          date_part('month', DealerTime) month_t,
          date_part('year', DealerTime) year_t,
          count(*) AS daily_views
   FROM ga
   WHERE ((GA.page_path) :: text ~~* '%/reports/%' :: text)
   GROUP BY Property,
            page_path_fixed,
            day_t,
            month_t,
            year_t,
            dpid,
            agent_email )


SELECT 
      case when GAday.page_path_fixed = 'kpis' then 'Performance/KPIs (Default)' 
      when GAday.page_path_fixed = 'overview' then 'Traffic/Overview' 
      when GAday.page_path_fixed = 'summary' then 'Prospects/Summary'
      when GAday.page_path_fixed = 'certification' then 'Agent/Certification'
      when GAday.page_path_fixed = 'close rate' then 'Prospects/Close Rate'
      when GAday.page_path_fixed = 'utilization' then 'Agent/Utilization'
      when GAday.page_path_fixed = 'utilization v2' then 'Agent/Utilization (V2)'
      when GAday.page_path_fixed = 'orders' then 'Prospects/Orders'
      when GAday.page_path_fixed = 'details' then 'Prospects/Details'
      when GAday.page_path_fixed = 'session level metrics bou' then 'Traffic/Bounce Rate'
      when GAday.page_path_fixed = 'orders f i and accessorie' then 'Prospects/Orders F&I and Accessories'
      
      else initcap(GAday.page_path_fixed) end  "Report Type", 
       sum(GAday.daily_views) "Report Views"

FROM GAday
LEFT JOIN fact.salesforce_dealer_info sf
  ON GAday.dpid = sf.dpid
  WHERE sf.status = 'Live'

GROUP BY "Report Type"
ORDER BY "Report Views" DESC;