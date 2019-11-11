
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
and admin.properties ->> 'status' <> 'Pending'
group by 1,2
),
pending_dpids as (SELECT distinct 
                        admin.date::date as date, 
                        dealer_partner_id,
                        admin.properties ->> 'status' "Status"
                      FROM dealer_partner_properties admin
                      
                      where admin.properties ->> 'status' is not Null
                      and admin.properties ->> 'status' ='Pending'

),
early_pending as (select dealer_partner_id 
                          ,min(date) as first_pending_date
                      from pending_dpids      
                      group by 1
            )



select * FROM
(
SELECT * FROM by_status
UNION
select date 
      ,case when date-first_pending_date <=30 then 'Pending < 30 Days'
            when date-first_pending_date <=91 then 'Pending 31 - 91 days'
            else 'Pending > 91 Days' end as status
      ,count(1)      
from pending_dpids pd
left join early_pending ep on pd.dealer_partner_id=ep.dealer_partner_id
group by 1,2
)z
order by 2 desc
