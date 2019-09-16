-- This report accesses the following tables - PLEASE KEEP THIS UPDATED --
-- public.ga2_pageviews
-- ga_pageviews
-- fact.salesforce_dealer_info

WITH GA AS
  (
  SELECT ga2_pageviews.id,
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
     GAday AS
  (SELECT Property,
          left(btrim(regexp_replace(regexp_replace((GA.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)),25) AS page_path_fixed,
          dpid,
          email agent_email,
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
      case when GAday.page_path_fixed = 'kpis' then 'Performance/KPIs (Default) [Tableau]' 
      when GAday.page_path_fixed = 'overview' then 'Traffic/Overview [Tableau]' 
      when GAday.page_path_fixed = 'summary' then 'Prospects/Summary [Tableau]'
      when GAday.page_path_fixed = 'certification' then 'Agent/Certification [Bespoke]'
      when GAday.page_path_fixed = 'close rate' then 'Prospects/Close Rate [Tableau]'
      when GAday.page_path_fixed = 'utilization' then 'Agent/Utilization [MODE]'
      when GAday.page_path_fixed = 'orders' then 'Prospects/Orders [Tableau]'
      when GAday.page_path_fixed = 'details' then 'Prospects/Details [Tableau]'
      when GAday.page_path_fixed = 'session level metrics bou' then 'Traffic/Bounce Rate [Tablea]'
      when GAday.page_path_fixed = 'orders f i and accessorie' then 'Prospects/Orders F&I and Accessories [Tableau]'
      when GAday.page_path_fixed = 'referral all' then 'Traffic/Referral ALL [Tableau]'
      when GAday.page_path_fixed = 'landing all' then 'Traffic/Landing ALL [Tableau]'
      
      when GAday.page_path_fixed = 'shares open click rates' then 'Agent/Shares Open Click Rates [MODE]'
      when GAday.page_path_fixed = 'shares open rate' then 'Agent/Shares Open Click Rates [MODE]'
      when GAday.page_path_fixed = 'prospects dashboard' then '{BETA}/Prospects Dashboard [MODE]'
      when GAday.page_path_fixed = 'sales dashboard' then '{BETA}/Sales Dashboard [MODE]'
      when GAday.page_path_fixed = 'traffic users' then '{BETA}/Traffic - Users [MODE]'
      when GAday.page_path_fixed = 'traffic behavior' then '{BETA}/Traffic - Behavior [MODE]'
      when GAday.page_path_fixed = 'traffic session metrics s' then '{BETA}/Traffic - Session Metrics (Site Type) [MODE]'
      when GAday.page_path_fixed = 'traffic session metrics n' then '{BETA}/Traffic - Session Metrics (New vs Used) [MODE]'
      when GAday.page_path_fixed = 'traffic session metrics a' then '{BETA}/Traffic - Session Metrics (Acquisition Type) [MODE]'
      when GAday.page_path_fixed = 'top referring and landing' then '{BETA}/Traffic - Top Referral and Landing Pages [MODE]'
      when GAday.page_path_fixed = 'dealer group report' then '{BETA}/Dealer Group Report [MODE]'
      
      else '*' || GAday.page_path_fixed end  "Report Type", 
       sum(GAday.daily_views) "Report Views",
       sum(case when GAday.agent_email ilike '%roadster.com%' then GAday.daily_views else 0 end) as "1) Report Views by Roadster Employees",
       sum(case when GAday.agent_email ilike '%roadster.com%' then 0 else GAday.daily_views end) as "2) Report Views by Customers"
       

FROM GAday
LEFT JOIN fact.salesforce_dealer_info sf
  ON GAday.dpid = sf.dpid
  WHERE sf.status = 'Live'
    --and GAday.dpid in('mbwestwood','applenissan','applechevrolet', 'audipasadena','hondaeastcincy', 'jimnortontoyota','legacytoyota','lexusofpleasanton','vistabmw')

GROUP BY "Report Type"
ORDER BY "Report Views" DESC;