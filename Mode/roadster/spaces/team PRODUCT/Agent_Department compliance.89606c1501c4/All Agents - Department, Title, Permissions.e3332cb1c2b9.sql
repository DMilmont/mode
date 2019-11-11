select 
dp.dpid
,dp.name as "Dealer Name"
, pa.first_name || ' ' || pa.last_name as "Agent"
, department as "Department"
, job_title as "Job Title"
, roles as "Permissions"
,last_login_at
, email as "Agent Email"
,city
,state
,zip

from public.agents pa 
left join public.dealer_partners dp on pa.dealer_partner_id = dp.id 
where pa.status = 'Active'
and last_login_at > now()- '1 year'::interval
order by dp.dpid, department, last_login_at desc 