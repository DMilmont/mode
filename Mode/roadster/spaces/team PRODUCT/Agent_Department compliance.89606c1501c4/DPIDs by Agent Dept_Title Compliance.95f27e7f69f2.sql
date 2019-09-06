
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
order by 2 DESC)


select 
  dpid
  ,to_char("Active Agents",'9990') "Agents with Activity"
  ,"No Department" || to_char(100 - "Has Department"::decimal / "Active Agents"::decimal *100 ,' (990%)') as "Agents missing Department"
  ,"No Job Title" || to_char(100 - "Has Job Title"::decimal / "Active Agents"::decimal *100 ,' (990%)') as "Agents missing Job Title"
  ,case when (100 - "Has Department"::decimal / "Active Agents"::decimal *100) > 80 and (100 - "Has Job Title"::decimal / "Active Agents"::decimal *100) > 80 then '1 EXCELLENT - > 80% Compliance'
  when (100 - "Has Department"::decimal / "Active Agents"::decimal *100) >80 then '2a EXCELLENT DEPARTMENT, Job Title needs improving'
  when (100 - "Has Job Title"::decimal / "Active Agents"::decimal *100) >80 then '2b EXCELLENT JOB TITLE compliance, Department needs improving'
  when (100 - "Has Department"::decimal / "Active Agents"::decimal *100) <25 and (100 - "Has Job Title"::decimal / "Active Agents"::decimal *100) <25 then '5 POOR Complaince - both under 25%'
  when (100 - "Has Department"::decimal / "Active Agents"::decimal *100) <25 then '4a POOR DEPARTMENT (<25%), mediocre Job Title Compliance'
  when (100 - "Has Department"::decimal / "Active Agents"::decimal *100) <25 or (100 - "Has Job Title"::decimal / "Active Agents"::decimal *100) <25 then '4b POOR JOB TITLE (<25%), mediocre Department Compliance'
  else '3 Mediocre' end as "Status"
 from jobtitle
--where ("Has Department"::decimal / "Active Agents"::decimal *100 <=25 or "Has Job Title"::decimal / "Active Agents"::decimal *100 <=25)
where "Active Agents" >= 5
order by "Status" ASC

;
