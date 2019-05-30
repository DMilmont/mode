-- Returns first 100 rows from public.dealer_partners
SELECT sf.integration_manager "Integration Manager",
        admin.State as "Admin State [please fix]", 
        sf.State as "Salesforce State", 
        admin.dpid as "Admin DPID", 
        admin.name as "Admin Dealer Name", 
        sf.status as "Salesforce Status"

FROM public.dealer_partners admin

left join fact.salesforce_dealer_info sf on admin.dpid = sf.dpid

where admin.state <> sf.state
and sf.status <> 'Cancelled'

order by sf.integration_manager ,admin.dpid 



