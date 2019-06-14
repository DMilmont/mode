with sessions as (
SELECT *
FROM george_personal.credit_sessions_level_table
WHERE dpid = '{{ dpid }}'
)

SELECT page_path "URL", SUM(1) "Views"
FROM sessions
WHERE page_path <> '/'
AND date_trunc('day', timestamp) > '2019-05-09'
GROUP BY 1
ORDER BY SUM(1) desc
 LIMIT 25