
 with instore as (SELECT dpid,
  sum(case when is_in_store = true then 1 else 0 end) "In Store",
  sum(case when is_in_store = false then 1 else 0 end) "Online"
FROM fact.f_prospect 
where step_date_utc > now() - interval '6 weeks'
  and item_type in ('OrderStarted', 'Order Submitted')
group by 1
)


SELECT date::date,
       sum(case when admin.properties ->> 'embedded_checkout_frame' = 'true' and instore."Online" >2 then 1 else 0 end) as "4 Slide-out and Using",
       sum(case when admin.properties ->> 'embedded_checkout_frame' = 'true' and instore."Online" <=2 then 1 else 0 end) as "3 Slide-out NOT Using",
       sum(case when admin.properties ->> 'embedded_checkout_frame' = 'false' and instore."Online" >2 then 1 else 0 end) as "2 In-Line and Using",
       sum(case when admin.properties ->> 'embedded_checkout_frame' = 'false' and instore."Online" <=2 then 1 else 0 end) as "1 In-Line NOT Using"
       
FROM dealer_partner_properties admin
left join dealer_partners dp on dp.id = admin.dealer_partner_id
left join instore on instore.dpid = dp.dpid
WHERE admin.properties ->> 'status' = 'Live'
  --and date > date('10/12/18')
GROUP BY date
