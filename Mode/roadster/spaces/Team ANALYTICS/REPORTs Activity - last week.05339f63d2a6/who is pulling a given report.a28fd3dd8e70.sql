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
            
select * from GAday 
--where dpid in('mbwestwood','applenissan','applechevrolet', 'audipasadena','hondaeastcincy', 'jimnortontoyota','legacytoyota','lexusofpleasanton','vistabmw')
--limit 100 