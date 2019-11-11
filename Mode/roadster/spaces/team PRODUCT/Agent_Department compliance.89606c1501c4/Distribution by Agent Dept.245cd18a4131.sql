
with agents_with_events as (
SELECT distinct agent_id FROM public.user_events where agent_id is not null 
)

SELECT
    pa.department
    ,count(1)

FROM public.agents pa 
left join public.dealer_partners dp on dp.id = pa.dealer_partner_id
left join fact.salesforce_dealer_info sf on dp.dpid = sf.dpid
left join agents_with_events ae on ae.agent_id = pa.id 
where pa.status = 'Active'
and (sf.status = 'Live' or dp.status = 'Live')
and ae.agent_id is not null
and pa.department is not NULL
group by 1
order by 2 DESC



;
