
SELECT 
    case when crm.sold_at >= now() - '7 days'::interval then 'period 0' 
         when crm.sold_at > now() - '7 weeks'::interval and crm.sold_at <= now() - '20 days'::interval then 'Period 1'
         else 'Period 2'
    end as "Period",
        
    sum(case when s.item_type = 'Matched Sale' and crm.sold_at >= now() - '7 days'::interval then 1 
             when s.item_type = 'Matched Sale' then 0.25
             else Null end) as "CDK Matches"

FROM public.crm_records crm

left join dealer_partners dp on crm.dealer_partner_id = dp.id
left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid
left join fact.f_sale s on  s.crm_record_id = crm.id 


where crm.status = 'Sold'
  and crm_type = 'cdk'
  and item_type is not null 
  and crm.sold_at > sf.actual_live_date
  and crm.sold_at > now() - '11 weeks'::interval

group by 1
order by 1 asc
 
