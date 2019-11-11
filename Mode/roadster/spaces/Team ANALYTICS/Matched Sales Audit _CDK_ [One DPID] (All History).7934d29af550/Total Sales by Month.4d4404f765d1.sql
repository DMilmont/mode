

with tab1 as (

SELECT 
 --   ROW_NUMBER() OVER(PARTITION BY crm.vin) vin_count,
    to_char(((s.first_lead_timestamp at time zone 'utc') at time zone 'utc'), 'YYYY-Mon') "First-Lead Month",
    to_char(((s.first_lead_timestamp at time zone 'utc') at time zone 'utc'), 'YYYY-MM') "First-Lead MM",
    to_char(s.first_lead_timestamp, 'YYYY-Mon') "First Lead Month UTC",
    to_char(crm.sold_at,'YYYY-Mon-DD') "Sold Date",
    crm.agent1 "Sales Agent",
    crm.first_name || ' ' || left(crm.last_name,1) || '.' "Customer Name",
    crm.vin "VIN",
    initcap(crm.grade) || ' ' || crm.year || ' ' || crm.make || ' ' ||  crm.model "Vehicle",
    to_char(crm.msrp, '999,999') "Price - MSRP",
    crm.deal_type "Deal Type",
    crm.term "Term",
    to_char(crm.payment ,'999,999.99') "Payment",
    to_char(crm.taxes, '999,999.99') "Taxes",
    to_char(crm.gross_profit, '999,999.99') "Gross",
    to_char(crm.back_end_gross_profit, '999,999.99') "Back Gross",
    to_char(crm.front_end_gross_profit, '999,999.99') "Front Gross",
    crm.trade_allowance,
    crm.net_trade,
    crm.trade_actual_cash_value,
    crm.id as "CRM ID",
    crm.stock_number "Stock Number",
    to_char(s.first_lead_timestamp, 'YYYY-MM-DD fmhh:MM AM') "First Lead",
    to_char(s.last_lead_timestamp, 'YYYY-MM-DD fmhh:MM AM') "Last Lead",
    --to_char(((s.first_lead_timestamp at time zone 'utc') at time zone dp.timezone), 'YYYY-MM-DD fmhh:MM AM') "First Lead",
    --to_char(((s.last_lead_timestamp at time zone 'utc') at time zone dp.timezone), 'YYYY-MM-DD fmhh:MM AM') "Last Lead",
    case when s.first_is_in_store = 'true' then 'In Store ' else 'Online ' end || s.first_prospect_type "First Lead Type",
    case when s.first_lead_timestamp = s.last_lead_timestamp then '' else case when s.last_is_in_store = 'true' then 'In Store ' else 'Online ' end || s.last_prospect_type end "Last Lead Type",
    s.days_to_close_from_first_lead "Days to close from 1st lead",
    case when s.first_lead_timestamp = s.last_lead_timestamp then null else s.days_to_close_from_last_lead end "Days to close from last lead",
    s.days_to_close_from_first_lead - s.days_to_close_from_last_lead "Days using Roadster",
    s.count_matched_leads "Total Roadster leads submitted"

FROM public.crm_records crm

left join dealer_partners dp on crm.dealer_partner_id = dp.id
left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid
left join fact.f_sale s on  s.crm_record_id = crm.id 


where dp.dpid = '{{ dpid }}'
  and crm_type = 'cdk'
  and crm.status = 'Sold'
  and item_type = 'Matched Sale'

order by to_char(((s.first_lead_timestamp at time zone 'utc') at time zone dp.timezone), 'YYYY-MM') desc , sold_at desc
)

select "First-Lead Month", count("First-Lead Month") "Roadster Sales"
from tab1

group by "First-Lead Month", "First-Lead MM"
order by "First-Lead MM" DESC