SELECT count(dpid),
      properties ->> 'crm_vendor' "Vendor"
FROM dealer_partner_properties dpp
LEFT JOIN dealer_partners dp ON dpp.dealer_partner_id = dp.id
WHERE date = (SELECT MAX(date) FROM dealer_partner_properties)
--AND properties ->> 'crm_vendor' ILIKE '%Socket%'
AND dp.status = 'Live'
group by properties ->> 'crm_vendor' 
ORDER BY count DESC