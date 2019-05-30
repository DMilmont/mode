-- Returns first 100 rows from public.lead_submitted
select 
  timestamp::date lead_date
, l.type
, count(distinct l.user_id) customer_count
, count(distinct l.id) lead_count
from lead_submitted l 
where 1=1 
--and type = 'SoftCreditInquiry' 
and timestamp >= date_trunc('month', current_date) - interval '6 month' 
and timestamp < date_trunc('month', current_date)
GROUP by lead_date, type 
