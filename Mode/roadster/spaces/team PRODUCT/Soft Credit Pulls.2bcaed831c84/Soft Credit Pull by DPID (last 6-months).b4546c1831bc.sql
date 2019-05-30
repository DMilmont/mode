select 
  l.dealer_partner_id
, dp.dpid
, count(distinct l.id)
from public.lead_submitted l 
JOIN public.dealer_partners dp ON l.dealer_partner_id = dp.id
where l.type = 'SoftCreditInquiry' AND l.in_store = true
and l.timestamp::date >= date_trunc('month', current_date) - interval '6 month' 
and l.timestamp::date < date_trunc('month', current_date)
group by l.dealer_partner_id, dp.dpid;
