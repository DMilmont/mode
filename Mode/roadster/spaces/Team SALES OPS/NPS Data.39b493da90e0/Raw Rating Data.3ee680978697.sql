SELECT 
r.timestamp,
dpid, 
primary_make,
u.first_name || ' '|| u.last_name "Customer Name",
u.email "Customer Email",
'dealers.roadster.com/' || dp.dpid || '/ratings' "url",
r.recommend,
CASE WHEN r.recommend > 8 THEN 1 ELSE 0 END "Promoters",
CASE WHEN r.recommend < 7 THEN 1 ELSE 0 END "Detractors"
FROM rating r
LEFT JOIN dealer_partners dp ON r.dealer_partner_id = dp.id
LEFT JOIN users u ON r.user_id = u.id
WHERE recommend IS NOT NULL
AND r.timestamp >= '{{ start_date }}'
AND r.timestamp < '{{ end_date }}'
