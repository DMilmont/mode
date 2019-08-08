
with dealer_activity as (SELECT
  date_trunc('week',step_date_utc) as date 
  ,dpid
  ,count(distinct customer_email) "unique_users"
  from fact.f_prospect
  group by 1,2
)

,active_dealers as (SELECT
  date,
  'Actually Using' as "Status", 
  count(dpid) as "Status_Count"
  from dealer_activity
  where unique_users>=2 --they just have to have 2 unique users in a given week to be considered 'active'
  and date is not null --not sure how that null got in there
  and date < date_trunc('week',now()) -- exclude any partial week to avoid the dreaded nose-dive at the right of the report. 
  group by 1
)

, by_status as (SELECT 
  admin.date::date, 
  admin.properties ->> 'status' "Status",
  count(admin.properties ->> 'status') "Status_Count"
FROM dealer_partner_properties admin

where admin.properties ->> 'status' is not Null
and admin.properties ->> 'status' <> 'Demo'
and admin.properties ->> 'status' <> 'Prospect'
and admin.properties ->> 'status' <> 'Terminating'
and admin.properties ->> 'status' <> 'Cold'
group by 1,2
)


--SELECT * FROM active_dealers -- this pulls in the Customer Activity line
--UNION
SELECT * FROM by_status
order by "Status" desc, date asc
-- NOTE - this order is important... the most recent "Active Customer Count" needs to be very last record to power the big number
;