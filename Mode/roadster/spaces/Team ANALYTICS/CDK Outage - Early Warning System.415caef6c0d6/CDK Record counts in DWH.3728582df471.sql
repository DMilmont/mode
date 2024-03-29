

SELECT 
    dp.dpid,
    crm.sold_at::date "Sale Day",
    count(distinct dp.dpid) "Distinct DPID",
    count(case when item_type = 'Matched Sale' then 1 else Null end) "Roadster Sale",
    count(case when item_type = 'Sale' then 1 else NULL end) "Non-Roadster Sale",
    count(crm.vin) "VINs",
    count(crm.cash_price) "Cash_Price Records",
    count(crm.gross_profit) "Gross Profit Records",
    count(crm.front_end_gross_profit) "FrontEnd Profit Records",
    count(crm.back_end_gross_profit) "BackEnd Profit Records",
    count(crm.agent1) "Agents"

FROM public.crm_records crm

left join dealer_partners dp on crm.dealer_partner_id = dp.id
left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid
left join fact.f_sale s on  s.crm_record_id = crm.id 


where crm.status = 'Sold'
  and crm_type = 'cdk'
  and item_type is not null 
  and crm.sold_at < now()
  and crm.sold_at > sf.actual_live_date
  and crm.sold_at > now() - '13 weeks'::interval

group by 1,2

order by 1,2
