SELECT
dpid,
fs.sold_date "Sell Date",
(date_trunc('month', fs.sold_date) + '1 day'::interval) "mth_yr", 
fs.vin "VIN",
fs.grade "Sale Grade",
last_lead_timestamp "timestamp",
regexp_replace(last_prospect_type, '([a-z])([A-Z])', '\1 \2','g') "Prospect Type",
last_email "Customer Email",
fs.days_to_close_from_last_lead "Days to Close",
'https://dealers.roadster.com/' || dpid || '/user_contacts/' || user_contact_dbid  "Link to Lead",
'Sa' title,
1 exists_now
FROM fact.f_sale fs
LEFT JOIN lead_submitted ls ON fs.last_lead_id = ls.id
WHERE dpid = '{{ dpid }}'
AND item_type ILIKE '%matched%'
AND first_prospect_type IS NOT NULL
AND fs.days_to_close_from_last_lead <= 90
ORDER BY sold_date desc