
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
  sum(case when is_in_store = true then 1 else 0 end) "In Store",
  sum(case when is_in_store = false then 1 else 0 end) "Online"
FROM fact.f_prospect 
where step_date_utc > now() - interval '1 month'
  and item_type in ('OrderStarted', 'Order Submitted')
group by 1
),

raw_sale_data as (
SELECT DISTINCT sold_date::date, item_type, dpid, vin, days_to_close_from_last_lead
FROM fact.f_sale
WHERE sold_date >= (date_trunc('day', now()) - INTERVAL '1 month')
),

sale_data_last_month as (
SELECT dpid,
COUNT (DISTINCT CASE WHEN item_type = 'Sale' THEN vin ELSE NULL END) AS all_sales,
COUNT (DISTINCT CASE WHEN item_type = 'Matched Sale' AND days_to_close_from_last_lead < 91 THEN vin ELSE NULL END) AS matched_sales
FROM raw_sale_data
where sold_date > now() - interval '1 month'
GROUP BY dpid
)



SELECT 
       dp.dpid,
       dp.name,
       dp.primary_make,
       dp.inventory_type,
       dp.city,
       dp.state,
       dp.price_unlock_mode,
       case when admin.properties ->> 'embedded_checkout_frame' = 'true' then 'Slide Out' else Null end as "Slide-out",
       dp.status "Dealer.Admin Status"

FROM dealer_partner_properties admin

LEFT JOIN dealer_partners dp  ON admin.dealer_partner_id = dp.id
LEFT JOIN fact.salesforce_dealer_info sf ON sf.dpid = dp.dpid
LEFT JOIN dealer_visitors on dealer_visitors.dpid = dp.dpid
LEFT JOIN online_express_traffic on online_express_traffic.dpid = dp.dpid
LEFT JOIN online_SRP_traffic srp on srp.dpid = dp.dpid
LEFT JOIN online_VDP_traffic vdp on vdp.dpid = dp.dpid
LEFT JOIN instoreP on instoreP.dpid = dp.dpid
LEFT JOIN instoreO on instoreO.dpid = dp.dpid
left join sale_data_last_month sd on sd.dpid = dp.dpid

WHERE admin.date = '{{admin_date}}'::date
and (sf.status = 'Live' or dp.status = 'Live')
and admin.properties ->> 'use_server_calculation_engine' = 'true'

ORDER BY dp.dpid;


{% form %}

admin_date:
  type: date
  default: {{ 'now' | date: '%s' | minus: 111600 | date: '%Y-%m-%d' }}
  description: Show what Dealer Admin looked like on this date

{% endform %}