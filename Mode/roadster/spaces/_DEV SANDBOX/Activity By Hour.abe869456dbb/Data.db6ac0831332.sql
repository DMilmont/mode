SELECT 
phu.*
FROM report_layer.per_hour_usage phu
LEFT JOIN dealer_partners dp ON phu.name = dp.name
WHERE phu.name = {{ dealer_name }}