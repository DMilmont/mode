SELECT page_path "URL", SUM(pageviews) "Views"
FROM fact.f_traffic
INNER JOIN dealer_partners dp ON fact.f_traffic.dpid = dp.dpid
WHERE date > DATE'2019-05-09'
AND dp.primary_make = '{{ Primary_Make }}'
AND dp.state = '{{ State }}'
AND page_path <> '/'
GROUP BY 1 
ORDER BY sum(pageviews) DESC
 LIMIT 25