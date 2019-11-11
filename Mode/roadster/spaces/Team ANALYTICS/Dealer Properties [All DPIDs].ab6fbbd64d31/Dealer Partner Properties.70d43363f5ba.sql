
with traffic as ( select *
from fact.mode_agg_daily_traffic_and_prospects ft
where ft.date between current_date-8 and current_date-1
and type in ('Dealer Visitors','Online Express Traffic','In-Store Shares', 'Online Express SRP Traffic', 'Online Express VDP Traffic')
)

,dealer_visitors  as (
select  dpid, sum(count) "count"
from traffic
where type = 'Dealer Visitors'
group by 1)

,online_express_traffic as (
select   dpid, sum(count) "count"
from traffic
where type = 'Online Express Traffic'
group by 1)

,online_VDP_traffic as (
select   dpid, sum(count) "count"
from traffic
where type = 'Online Express VDP Traffic'
group by 1)

,online_SRP_traffic as (
select   dpid,sum(count) "count"
from traffic
where type = 'Online Express SRP Traffic'
group by 1)



,instoreP as (SELECT dpid,
  sum(case when is_in_store = true then 1 else 0 end) "In Store",
  sum(case when is_in_store = false then 1 else 0 end) "Online"
FROM fact.f_prospect 
where step_date_utc > now() - interval '1 month'
group by 1
)

,instoreO as (SELECT dpid,
  count (/*DISTINCT*/ customer_email) "Orders"
FROM fact.f_prospect 
where step_date_utc > now() - interval '1 month'
  and item_type in ('OrderStarted' /*, 'Order Submitted' */)
  and  is_in_store = true
group by 1
)

,onlineO as (SELECT dpid,
  count (/*DISTINCT*/ customer_email) as "Orders"
FROM fact.f_prospect 
where step_date_utc > now() - interval '1 month'
  and item_type in ('OrderStarted' /*, 'Order Submitted' */)
  and  is_in_store = false
group by 1
)

,raw_sale_data as (
SELECT DISTINCT sold_date::date, item_type, dpid, vin, days_to_close_from_last_lead
FROM fact.f_sale
WHERE sold_date >= (date_trunc('day', now()) - INTERVAL '1 month')
)

,sale_data_last_month as (
SELECT dpid,
COUNT (DISTINCT CASE WHEN item_type = 'Sale' THEN vin ELSE NULL END) AS all_sales,
COUNT (DISTINCT CASE WHEN item_type = 'Matched Sale' AND days_to_close_from_last_lead < 91 THEN vin ELSE NULL END) AS matched_sales
FROM raw_sale_data
where sold_date > now() - interval '1 month'
GROUP BY dpid
)



SELECT 
       sf.status "SF Status",
       dp.status "Dealer.Admin Status",
       dp.dpid,
       dp.name,
       sf.dealer_group,
       dp.ga_tracking_id "Roadster's GA Property",
       admin.properties ->> 'ga_accounts' "Customer GA Account",
       admin.properties ->> 'gtm_account' "Customer GTM Container",
       admin.dealer_partner_id,
       dp.tableau_secret "Secret",        
       case when admin.properties ->> 'use_server_calculation_engine' = 'true' then 'SERVER' else '' end as "New Server Calc?",
       case 
          when dp.dpid = 'roadster' then '-DEFAULT-'
          when admin.properties ->> 'reports' is null then '' 
          else 'CUSTOMIZED' 
       end as "Custom Reports?",
       dp.price_unlock_mode,
       --admin.properties ->> 'embedded_checkout_frame' "Slide-out",
       case when admin.properties ->> 'embedded_checkout_frame' = 'true' then 'Slide Out' else Null end as "Slide-out",
       admin.properties ->> 'cdk_extract_id' "CDK Sales Match",
       to_char(sf.actual_live_date, 'yyyy-mm-dd') "Go Live Date",
       case when dealer_visitors.count is null then 'Script not Installed' else dealer_visitors.count::text end as "Dealer Visitors past wk",
       online_express_traffic.count "Online ES Visitors past wk",
       srp.count as "SRP Visitors past wk",
       vdp.count as "VDP Visitors past wk",
       instoreP."In Store" + instoreP."Online" "Prospects past mo",
       instoreO."Orders" "In Store Orders past mo",
       onlineO."Orders" "Online Orders past mo",
       sd.matched_sales "Matched Sales past mo",
       sd.all_sales "All Sales past mo",
       round((instoreP."In Store"::decimal / (instoreP."In Store" + instoreP."Online")) * 100,0) as "In Store Prospect %",
       round((instoreO."Orders"::decimal / (instoreO."Orders" + onlineO."Orders")) * 100,0) as "In Store Order %",
       sf.success_manager AS "SF Success Manager",
       sf.account_executive AS "SF Account Executive",
       sf.integration_manager as "Integration Manager",
       dp.primary_make,
       dp.inventory_type,
       dp.marketplace_type,
       admin.properties ->> 'crm_vendor' "Dealer Admin CRM",
       dp.city,
       dp.state,
       --dp.zip,
       dp.timezone

      --,admin.properties 

       ------ KBB ICO TRADE FLAGS ------
       --admin.properties ->> 'kbb_ico_iframe_url' "kbb_ico_iframe_url",
       --admin.properties ->> 'kbb_widget_api_key' "kbb_widget_api_key",
       --admin.properties ->> 'fetch_kbb_tradein_value' "fetch_kbb_tradein_value",
       --admin.properties ->> 'kbb_valuation_supported' "kbb_valuation_supported",
       --admin.properties ->> 'external_trade_valuation' "external_trade_valuation",
       --admin.properties ->> 'tradein_url' "tradein_url",
       --admin.properties ->> 'allow_standalone_trade' "allow_standalone_trade",
       --admin.properties ->> 'instant_trade_valuation' "instant_trade_valuation",
       --admin.properties ->> 'ico_params' "ico_params",
       --admin.properties ->> 'custom_ico_url' "custom_ico_url"
       
       
       
       


FROM dealer_partner_properties admin

LEFT JOIN dealer_partners dp  ON admin.dealer_partner_id = dp.id
LEFT JOIN fact.salesforce_dealer_info sf ON sf.dpid = dp.dpid
LEFT JOIN dealer_visitors on dealer_visitors.dpid = dp.dpid
LEFT JOIN online_express_traffic on online_express_traffic.dpid = dp.dpid
LEFT JOIN online_SRP_traffic srp on srp.dpid = dp.dpid
LEFT JOIN online_VDP_traffic vdp on vdp.dpid = dp.dpid
LEFT JOIN instoreP on instoreP.dpid = dp.dpid
LEFT JOIN instoreO on instoreO.dpid = dp.dpid
LEFT JOIN onlineO on onlineO.dpid = dp.dpid
left join sale_data_last_month sd on sd.dpid = dp.dpid

WHERE admin.date = '{{admin_date}}'::date
--and (sf.status = 'Live' or dp.status = 'Live' or dp.status = 'Demo')

ORDER BY dp.dpid;


{% form %}

admin_date:
  type: date
  default: {{ 'now' | date: '%s' | minus: 111600 | date: '%Y-%m-%d' }}
  description: Show what Dealer Admin looked like on this date

{% endform %}