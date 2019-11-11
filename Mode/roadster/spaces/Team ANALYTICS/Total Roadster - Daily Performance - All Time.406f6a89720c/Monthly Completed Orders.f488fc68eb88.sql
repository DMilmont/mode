
SELECT oc.id, date_trunc('day',oc.timestamp), dp.dpid FROM public.order_completed oc
left join public.dealer_partners dp on dp.id = dealer_partner_id
where dp.dpid not ilike '%demo%'
