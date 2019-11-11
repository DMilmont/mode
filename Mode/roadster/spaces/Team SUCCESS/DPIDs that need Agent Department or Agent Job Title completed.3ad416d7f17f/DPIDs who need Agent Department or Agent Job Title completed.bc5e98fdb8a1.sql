
with agents_with_events as (
SELECT distinct agent_id FROM public.user_events where agent_id is not null 
)

,jobtitle as (
SELECT
    dp.dpid
    ,sf.success_manager
    ,sum(case when pa.job_title isNull then 1 else 0 end) as "No Job Title"
    ,sum(case when pa.job_title isnull then 0 else 1 end) as "Has Job Title"
    ,sum(case when pa.department isnull then 0 else 1 end) as "Has Department"
    ,sum(case when pa.department isNull then 1 else 0 end) as "No Department"
    ,count(1) as "Active Agents"

FROM public.agents pa 
left join public.dealer_partners dp on dp.id = pa.dealer_partner_id
left join fact.salesforce_dealer_info sf on dp.dpid = sf.dpid
left join agents_with_events ae on ae.agent_id = pa.id 
where pa.status = 'Active'
and (sf.status = 'Live' or dp.status = 'Live')
and ae.agent_id is not null
group by 1,2
order by 2 DESC
)


select 
  success_manager "DSM"
  ,dpid
  ,'Very Few Agents have Agent Job Titles or Departments completed' as "Problem"
  ,to_char("Active Agents",'9990') "Agents with Activity"
  ,"No Department"
  ,"No Job Title"
  ,"No Department" || to_char(100 - "Has Department"::decimal / "Active Agents"::decimal *100 ,' (990%)') as "Agents missing Department"
    ,"No Job Title" || to_char(100 - "Has Job Title"::decimal / "Active Agents"::decimal *100 ,' (990%)') as "Agents missing Job Title"
 from jobtitle
where ("Has Department"::decimal / "Active Agents"::decimal *100 <=25 or "Has Job Title"::decimal / "Active Agents"::decimal *100 <=25)
and "Active Agents" > 5
order by "Active Agents" - ("Has Department" - "Has Job Title")/2 desc 

;
