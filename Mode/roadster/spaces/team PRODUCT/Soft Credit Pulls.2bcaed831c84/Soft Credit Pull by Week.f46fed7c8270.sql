-- Returns first 100 rows from public.lead_submitted
select 
  date_trunc('week', timestamp) as week
, count(type)
from lead_submitted
where type = 'SoftCreditInquiry' 
AND timestamp >= date_trunc('month', now()) - interval '6 month' 
and timestamp < date_trunc('month', now())
GROUP by week 
ORDER BY 1,2;