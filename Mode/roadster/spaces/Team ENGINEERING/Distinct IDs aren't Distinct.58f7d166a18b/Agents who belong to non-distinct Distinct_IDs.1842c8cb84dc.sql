with ab as (select distinct_id, count(distinct email) from public.agents
group by 1)
select ag.distinct_id "distinct id", ag.email "EMAIL", ag.*
from public.agents ag 
left join ab on ab.distinct_id = ag.distinct_id
where ab.count >1
order by ab.count desc 