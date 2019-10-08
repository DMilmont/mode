with ab as (select distinct_id, count(distinct email) from public.agents
group by 1)

select ag.distinct_id "distinct id", count(distinct ag.email) "Distinct Emails"
from public.agents ag 
left join ab on ab.distinct_id = ag.distinct_id
where ab.count >1
group by 1
