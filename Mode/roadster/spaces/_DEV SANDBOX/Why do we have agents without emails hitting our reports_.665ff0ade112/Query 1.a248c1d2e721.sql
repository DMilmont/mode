WITH GA AS
  (
  SELECT *
   
   FROM ga2_pageviews
      LEFT JOIN 
   (
   SELECT *
   FROM public.ga2_sessions
   WHERE agent_dbid ~ '^[0-9]*$'
   AND timestamp > (date_trunc('day' :: text, now()) - '30 days' :: interval)
   )
   gs ON ga2_pageviews.ga2_session_id = gs.id 
   LEFT JOIN public.dealer_partners dp ON gs.dpid = dp.dpid
   LEFT JOIN agents a ON (gs.agent_dbid)::integer = a.user_dbid
   WHERE Property = 'Dealer Admin'
     AND ((ga2_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME
          ZONE dp.timezone) > (date_trunc('day' :: text, now()) - '30 days' :: interval)

     ),
     GAday AS
  (SELECT *
   FROM ga
   WHERE ((GA.page_path) :: text ~~* '%/reports/%' :: text)
    and email is null 
   )
            
select * from GAday 
