
SELECT 
  date::date, 
  admin.properties ->> 'status' "Status",
  count(admin.properties ->> 'status') "Status_Count"
FROM dealer_partner_properties admin

where admin.properties ->> 'status' is not Null
and admin.properties ->> 'status' <> 'Demo'
and admin.properties ->> 'status' <> 'Prospect'
and admin.properties ->> 'status' <> 'Terminating'
and admin.properties ->> 'status' <> 'Cold'


group by date, "Status"
order by date DESC




