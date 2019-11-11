SELECT 
 --   ROW_NUMBER() OVER(PARTITION BY crm.vin) vin_count,
    --s.first_lead_id,
    dp.name "Dealer Name",
    case when s.item_type = 'Matched Sale' then 'Roadster'
         when s.item_type = 'Sale' then 'Non-Roadster'
         else s.item_type 
        end as "Sale Type",
    crm.crmid "Deal No",
    to_char(crm.sold_at,'YYYY-Mon-DD') "Sold Date",
    crm.stock_number "Stock Number",
    crm.vin "VIN",
    crm.agent1 "Sales Agent",
    initcap(crm.grade) "New/Used",
    crm.deal_type "Deal Type",
    crm.year || ' ' || crm.make || ' ' ||  crm.model "Vehicle",
    crm.mileage "Mileage",
    days_in_stock "Days in Stock",
    to_char(crm.msrp, '999,999') "MSRP",
    to_char(crm.invoice_price, '999,999')  "Invoice Price",
    to_char(crm.cash_price, '999,999') "Purchase Price",
    to_char(crm.front_end_gross_profit, '999,999.99') "Front Gross",
    to_char(crm.back_end_gross_profit, '999,999.99') "Back Gross",
    to_char(crm.total_gross, '999,999.99') "Total Gross",
    
    to_char(crm.down_payment, '999,999.99') "Down Payment",
    to_char(crm.amount_financed, '999,999.99') "Amount Financed",
    
    to_char(crm.payment ,'999,999.99') "Payment",
    to_char(crm.taxes, '999,999.99') "Taxes",
    crm.interest_rate || ' / ' || crm.interest_rate_buy "Rate(Sell/Buy)",
    crm.term "Term",

-- TRADE INFO --
    'coming soon' "Trade-in Vehicle",
    'coming soon' "Trade-in Mileage",
    'coming soon' "Trade-in VIN",
    to_char(crm.trade_allowance , '999,999.99') "Trade Allowance",
    to_char(crm.trade_actual_cash_value, '999,999.99') "Trade ACV",
    to_char(crm.net_trade, '999,999.99') "Trade - Net",
    to_char(crm.trade_payoff, '999,999.99') "Trade Payoff",

    crm.first_name || ' ' || left(crm.last_name,1) || '.' "Customer Name",
    to_char(s.first_lead_timestamp, 'YYYY-MM-DD fmhh:MM AM') "First Lead",
    to_char(s.last_lead_timestamp, 'YYYY-MM-DD fmhh:MM AM') "Last Lead",
    --to_char(((s.first_lead_timestamp at time zone 'utc') at time zone /*dp.timezone*/ 'utc'), 'YYYY-Mon-DD HH:MM AM') "First-Lead",
    --s.days_to_close_from_first_lead "Days to close",
    --to_char(((s.first_lead_timestamp at time zone 'utc') at time zone dp.timezone), 'YYYY-MM-DD fmhh:MM AM') "First Lead",
    --to_char(((s.last_lead_timestamp at time zone 'utc') at time zone dp.timezone), 'YYYY-MM-DD fmhh:MM AM') "Last Lead",
    case when s.first_is_in_store = 'true' then 'In Store ' else 'Online ' end || s.first_prospect_type "First Lead Type",
    case when s.first_lead_timestamp = s.last_lead_timestamp then '' else case when s.last_is_in_store = 'true' then 'In Store ' else 'Online ' end || s.last_prospect_type end "Last Lead Type",
    s.days_to_close_from_first_lead "Days to close from 1st Lead",
    case when s.first_lead_timestamp = s.last_lead_timestamp then null else s.days_to_close_from_last_lead end "Days to close from last lead",
    s.days_to_close_from_first_lead - s.days_to_close_from_last_lead "Days using Roadster",
    s.count_matched_leads "Total Roadster leads submitted",
    dp.primary_make as "Rooftop Primary Make",
    to_char(sf.actual_live_date,'YYYY-MM-DD') "Go Live Date"

FROM public.crm_records crm

left join dealer_partners dp on crm.dealer_partner_id = dp.id
left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid
left join fact.f_sale s on  s.crm_record_id = crm.id 


where  dp.dpid = '{{ dpid }}'
  and crm_type = 'cdk'
  and crm.status = 'Sold'
  and item_type = 'Sale'
  and crm.sold_at > sf.actual_live_date
and crm.sold_at > now() - '3 months'::interval

order by /*s.item_type asc,*/ crm.sold_at desc
