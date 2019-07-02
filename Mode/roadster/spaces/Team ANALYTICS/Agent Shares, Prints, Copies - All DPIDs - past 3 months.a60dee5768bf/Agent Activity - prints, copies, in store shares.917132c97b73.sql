-- Returns first 100 rows from public.agents
SELECT * FROM public.agents LIMIT 100;




with agent_prints_copies AS (
      SELECT (ue.payload ->> 'dpid' :: text)             AS dpid,
            --date_trunc('month' :: text, ue."timestamp")::date AS month_year,
            a.email agent_email,
             a.first_name,
             a.last_name,
             a.job_title,
             a.department,
             count(
               CASE
                 WHEN ((ue.name) :: text = 'Print Price Summary' :: text) THEN ue.id
                 ELSE NULL :: integer
                   END)                                  AS "Print Price Summary",
             count(
               CASE
                 WHEN ((ue.name) :: text = 'Print Share Details' :: text) THEN ue.id
                 ELSE NULL :: integer
                   END)                                  AS "Print Share Details",
             count(
               CASE
                 WHEN ((ue.name) :: text = 'Copy To Clipboard' :: text) THEN ue.id
                 ELSE NULL :: integer
                   END)                                  AS "Copies To Clipboard"
      FROM ((SELECT user_events.id,
                    user_events.user_event_dbid,
                    user_events.name,
                    user_events."timestamp",
                    user_events.payload,
                    user_events.dealer_partner_id,
                    user_events.distinct_id,
                    user_events.user_id,
                    user_events.in_store
             FROM user_events
             WHERE ((user_events.payload ->> 'agent_id' :: text) ~ '^[0-9]*$' :: text)) ue
          JOIN agents a ON ((((ue.payload ->> 'agent_id' :: text)) :: integer = a.user_dbid)))
      WHERE ((ue.user_id IS NOT NULL) AND ((ue.name) :: text = ANY
                                           (ARRAY[('Print Price Summary'::character varying)::text, ('Print Share Details'::character varying)::text, ('Copy To Clipboard'::character varying)::text])) AND
             (ue."timestamp" > (date_trunc('day' :: text, now())::date - '3 months' :: interval)))
      GROUP BY a.first_name, a.last_name, a.email,(ue.payload ->> 'dpid' :: text), a.job_title, a.department )
        
,in_store_shares as (
      SELECT dpid,
            --date_trunc('month', cohort_date_utc)::date month_year,
            agent_email,
            count( f_prospect.customer_email) as "In Store Shares"
      FROM fact.f_prospect
      WHERE item_type = 'SharedExpressVehicle'
      AND source = 'Lead Type'
      AND is_in_store = True
      and agent_email is not null
      and cohort_date_utc > (date_trunc('day' :: text, now()) - '3 months' :: interval)
GROUP BY 1,2
)

select 
       apc.agent_email "Agent Email"
       ,apc.department "Agent Department"
       ,apc.dpid
       ,COALESCE(iss."In Store Shares",0) "In Store Shares"
       ,apc."Copies To Clipboard"
       ,apc."Print Price Summary"
       ,apc."Print Share Details"
       ,apc."Print Price Summary" + apc."Print Share Details" + apc."Copies To Clipboard" + COALESCE(iss."In Store Shares",0) as "Total Activity"
       ,apc.first_name "Agent First Name"
       ,apc.last_name "Agent Last Name"
       ,apc.job_title "Agent Job Title"
from agent_prints_copies apc 
    left join in_store_shares iss on iss.dpid = apc.dpid and iss.agent_email = apc.agent_email --and iss.month_year = apc.month_year 
    where apc.agent_email not ilike '%roadster.com'
    order by "Total Activity" DESC
    


