select * 
from fact.salesforce_dealer_info sf
left join public.dealer_partners dp on dp.dpid = sf.dpid 
where dp.primary_make = 'All'
and sf.status = 'Live'