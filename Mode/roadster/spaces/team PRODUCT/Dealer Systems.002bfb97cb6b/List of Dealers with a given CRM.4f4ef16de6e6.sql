with da as (SELECT 
      dpid,
      name,
      properties ->> 'crm_vendor' "Vendor"
FROM dealer_partner_properties dpp
LEFT JOIN dealer_partners dp ON dpp.dealer_partner_id = dp.id
WHERE date = (SELECT MAX(date) FROM dealer_partner_properties)
--AND properties ->> 'crm_vendor' ILIKE '%Socket%'
AND dp.status = 'Live'
ORDER BY dp.name)


SELECT 
       sf.success_manager,
       sf.dpid "DPID",
       sf.dealer_name "Dealer Name",
       sf.crm "CRM in Salesforce",
       da."Vendor" "CRM in Dealer Admin"
       
       
FROM fact.salesforce_dealer_info sf
left join da on da.dpid = sf.dpid

WHERE sf.status = 'Live'

order by sf.success_manager, sf.dpid asc 
