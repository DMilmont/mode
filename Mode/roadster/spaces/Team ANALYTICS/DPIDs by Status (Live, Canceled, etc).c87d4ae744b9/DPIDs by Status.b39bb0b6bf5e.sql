

SELECT 
  date::date, 
  admin.properties ->> 'status' "Status",
  count(admin.properties ->> 'status') "Status_Count"
FROM dealer_partner_properties admin 
group by date, "Status"
order by date DESC
limit 1000



