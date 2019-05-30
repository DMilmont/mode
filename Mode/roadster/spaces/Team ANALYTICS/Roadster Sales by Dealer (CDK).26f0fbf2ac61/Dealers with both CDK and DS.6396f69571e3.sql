with tab1 as (
SELECT 
    dp.name "Dealer Name",
    dp.dpid,
    crm.dealer_partner_id,
    --to_char(crm.sold_at,'YYYY-Mon') "Sold Month",
    --item_type,
    --crm_type,
    sum(case when crm_type = 'dealer-socket' then 1 else null end) "Dealer Socket sales",
    sum(case when crm_type = 'cdk' then 1 else null end) "CDK sales"
   -- min(case when crm_type = 'cdk' then crm.sold_at else null end) as "First CRM Sales Record",
    -- min(case when crm_type = 'dealer-socket' then crm.sold_at else null end) as "First DS Sales Record"
    

FROM public.crm_records crm

left join dealer_partners dp on crm.dealer_partner_id = dp.id
left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid
left join fact.f_sale s on  s.crm_record_id = crm.id 

where crm.status = 'Sold'
  and crm.sold_at > date '01-01-2019'
  
group by 1,2,3

order by dp.name asc)

select * from tab1
where "Dealer Socket sales" > 0 and "CDK sales" >0 