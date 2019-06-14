SELECT page_path "URL", SUM(pageviews) "Views"
FROM fact.f_traffic
WHERE date > DATE'2019-05-09'
AND dpid = '{{ dpid }}'
AND page_path <> '/'
GROUP BY 1 
ORDER BY sum(pageviews) DESC
 LIMIT 25