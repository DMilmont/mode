with sessions as (
SELECT *
FROM george_personal.credit_sessions_level_table
WHERE dpid = '{{ dpid }}'
),

session_pages as (
  SELECT id, SUM(1) session_size
  FROM sessions
  WHERE page_path <> '/'
  AND date_trunc('day', timestamp) > '2019-05-09'
  GROUP BY id
),

avg_session_size as (
  SELECT AVG(session_size) "Average Session Size"
  FROM session_pages
)

SELECT MAX("Average Session Size") "Average Pages Visited",
       MODE() within group (ORDER BY full_referrer) "Most Common Referrer",
       ROUND((AVG(duration)::decimal / 60), 2) || ' '|| 'min' "Average Session Duration (in min)", 
       MODE() within group (ORDER BY landing_page_path) "Most Common Landing Page",
       MODE() within group (ORDER BY express_landing_page) "Most Common Express Landing Page",
       MODE() within group (ORDER BY browser) "Most Common Browser"
    
FROM sessions
LEFT JOIN avg_session_size ON 1=1
WHERE page_path <> '/'
AND date_trunc('day', timestamp) > '2019-05-09'