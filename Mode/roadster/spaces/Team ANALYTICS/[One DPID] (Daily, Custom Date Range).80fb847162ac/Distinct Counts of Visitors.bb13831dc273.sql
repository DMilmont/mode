WITH tab1 as (
  SELECT dpid, COUNT(DISTINCT gp.distinct_id) "Express Store Visitors"
  FROM public.ga2_pageviews gp
  INNER JOIN public.ga2_sessions gs ON gp.ga2_session_id = gs.id
  WHERE property = 'Express Sites'
  AND dpid = '{{ select_dpid }}'
  and gp.timestamp >= '{{ start_date }}'  
  and gp.timestamp <= '{{ end_date }}'
  and gs.timestamp >= '{{ start_date }}'  
  and gs.timestamp <= '{{ end_date }}'
  GROUP BY 1
)

SELECT gs.dpid "Rooftop", 
"Express Store Visitors",
COUNT(DISTINCT gp.distinct_id) "Dealer Website Visitors" 
FROM public.ga2_pageviews gp
INNER JOIN public.ga2_sessions gs ON gp.ga2_session_id = gs.id
LEFT JOIN tab1 on gs.dpid = tab1.dpid
WHERE property = 'Main Sites'
AND gs.dpid = '{{ select_dpid }}'
and gp.timestamp >= '{{ start_date }}'  
and gp.timestamp <= '{{ end_date }}'
and gs.timestamp >= '{{ start_date }}'  
and gs.timestamp <= '{{ end_date }}'
GROUP BY 1,2