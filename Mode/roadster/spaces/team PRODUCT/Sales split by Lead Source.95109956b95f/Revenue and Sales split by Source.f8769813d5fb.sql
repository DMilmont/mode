select 
dp.dpid,  
to_char(crm.sold_at,'YYYY') "year",
crm.source, -- this is '3' in the group by and Order by
--crm.grade,  -- this is '4' in the group by and Order by
--crm.deal_type,  -- this is '5' in the group by and Order by
---------------------------
count(vin) as "Units Sold",
sum(cash_price) as "dubious Revenue",
count(distinct to_char(crm.sold_at,'YYYYWW')) "weeks of data"


from public.crm_records crm
left join dealer_partners dp on crm.dealer_partner_id = dp.id
where 
crm_type = 'dealer-socket'
and crm.status = 'Sold'
and sold_at is not null 
group by 1,2,3 --,4,5
order by 1 asc, 2 desc, 4 desc

