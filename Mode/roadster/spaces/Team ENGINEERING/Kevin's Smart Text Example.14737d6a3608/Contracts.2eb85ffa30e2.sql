select 
  case when status in ('Pending Cancellation','Wind Down','Live') then 'Live'
  else 'In Dev' end status
, count(distinct dpid)
from fact.mode_sfdc_status
where status in ('Pending Cancellation','Wind Down','Live','Not Started','In Dev')
group by 1
