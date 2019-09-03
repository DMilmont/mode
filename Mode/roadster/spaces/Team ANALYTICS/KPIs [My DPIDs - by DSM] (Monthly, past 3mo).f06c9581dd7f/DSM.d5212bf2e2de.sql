select dsm,rnk from 
(
select distinct 'ALL' as dsm,1 rnk
from fact.d_cal_month
union
select sf.success_manager, 2
from fact.d_cal_month c
cross join (
  select distinct dpid, tableau_secret, name, status from dealer_partners
  ) dp
left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid
where c.month_year >= (date_trunc('day', now()) - INTERVAL '91 days')
and (sf.status = 'Live' or dp.status = 'Live')
and success_manager is not null
group by 1
)z
order by 2,1

{% form %}

dsm: 
  type: select
  options: 
    labels: dsm
    values: dsm
    default: 'ALL'
  description: Please select DSM to see your dealers  

{% endform %}