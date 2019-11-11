-- Returns first 100 rows from public.lead_submitted
SELECT 
    dp.dpid
    , ls.type
    , timestamp
    , us.email
    , sent_at
    , delivered_at
    , opened_at
    , clicked_at
    , ag.first_name || ' ' || ag.last_name "agent"
    , ag.email as "agent_email"
    , ag.job_title
    , ag.department
    , ag.distinct_id
    , ls.agent_id
    , ls.in_store
    

FROM public.lead_submitted ls
left join public.dealer_partners dp on dp.id = ls.dealer_partner_id
left join public.agents ag on ag.id = ls.agent_id
left join public.users us on ls.user_contact_dbid = us.id

where ls.in_store = true
and sent_at is not null 
and timestamp >= '06/01/2019'::date 

order by timestamp desc 
;

