

with traffic as ( select *
from fact.mode_agg_daily_traffic_and_prospects ft
where ft.date between current_date-8 and current_date-1
and type in ('Dealer Visitors','Online Express Traffic','In-Store Shares')
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

,instoreP as (SELECT dpid,
  sum(case when is_in_store = true then 1 else 0 end) "In Store",
  sum(case when is_in_store = false then 1 else 0 end) "Online"
FROM fact.f_prospect 
where step_date_utc > now() - interval '1 month'
group by 1
)

,instoreO as (SELECT dpid,
  sum(case when is_in_store = true then 1 else 0 end) "In Store",
  sum(case when is_in_store = false then 1 else 0 end) "Online"
FROM fact.f_prospect 
where step_date_utc > now() - interval '1 month'
  and item_type in ('OrderStarted', 'Order Submitted')
group by 1
)


SELECT 

       dp.dpid,
       admin.dealer_partner_id,
       dp.name,
       dp.ga_tracking_id "Roadster's GA Property",
       admin.properties ->> 'ga_accounts' "Customer GA Account",
       admin.properties ->> 'gtm_account' "Customer GTM Container",
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
       instoreP."In Store" + instoreP."Online" "Prospects",
       instoreO."In Store" + instoreO."Online" "Orders",
       round((instoreP."In Store"::decimal / (instoreP."In Store" + instoreP."Online")) * 100,0) as "In Store Prospect %",
       round((instoreO."In Store"::decimal / (instoreO."In Store" + instoreO."Online")) * 100,0) as "In Store Order %",
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
       dp.timezone,
       sf.status "SF Status",
       dp.status "Dealer.Admin Status"
       
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
       
       
       
       
       --,admin.properties 

FROM dealer_partner_properties admin

LEFT JOIN dealer_partners dp  ON admin.dealer_partner_id = dp.id
LEFT JOIN fact.salesforce_dealer_info sf ON sf.dpid = dp.dpid
LEFT JOIN dealer_visitors on dealer_visitors.dpid = dp.dpid
LEFT JOIN online_express_traffic on online_express_traffic.dpid = dp.dpid
LEFT JOIN instoreP on instoreP.dpid = dp.dpid
LEFT JOIN instoreO on instoreO.dpid = dp.dpid

WHERE admin.date = '{{admin_date}}'::date
and (sf.status = 'Live' or dp.status = 'Live')

ORDER BY dp.dpid;


{% form %}

admin_date:
  type: date
  default: {{ 'now' | date: '%s' | minus: 111600 | date: '%Y-%m-%d' }}
  description: Show what Dealer Admin looked like on this date

{% endform %}