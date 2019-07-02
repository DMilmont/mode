 with instore as (SELECT dpid,
  sum(case when is_in_store = true then 1 else 0 end) "In Store",
  sum(case when is_in_store = false then 1 else 0 end) "Online"
FROM fact.f_prospect 
where step_date_utc > now() - interval '6 weeks'
  and item_type in ('OrderStarted', 'Order Submitted')
group by 1
)


SELECT date::date,
       sum(CASE WHEN admin.properties ->> 'in_store_purchase_wizard' = 'true' and instore."In Store" >2 THEN 1 ELSE 0 END) AS "4 Enabled and Using",
       sum(CASE WHEN admin.properties ->> 'in_store_purchase_wizard' = 'true' and instore."In Store" <=2 THEN 1 ELSE 0 END) AS "3 Enabled NOT Using",
       sum(CASE WHEN admin.properties ->> 'in_store_purchase_wizard' = 'false' and instore."In Store" >2 THEN 1 ELSE 0 END) AS "2 Disabled and should be using",
       sum(CASE WHEN admin.properties ->> 'in_store_purchase_wizard' = 'false' and instore."In Store" <=2 THEN 1 ELSE 0 END) AS "1 Disabled but No Instore Orders"
FROM dealer_partner_properties admin
left join dealer_partners dp on dp.id = admin.dealer_partner_id
left join instore on instore.dpid = dp.dpid
WHERE admin.properties ->> 'status' = 'Live'
  and date > date('10/12/18')
GROUP BY date
