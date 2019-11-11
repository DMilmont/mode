
SELECT *
FROM public.user_events where dealer_partner_id = '2555734'
order by timestamp DESC
limit 100000

;