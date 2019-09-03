
SELECT dp.dpid,
       properties -> 'cdk_extract_id' AS "cdk_extract_id"
FROM public.dealer_partner_properties dpp
left join public.dealer_partners dp ON dp.id = dpp.dealer_partner_id
WHERE date > (date_trunc('day', now()) - INTERVAL '1 day')
  AND properties -> 'cdk_extract_id' <> 'null'
ORDER BY dpid ASC