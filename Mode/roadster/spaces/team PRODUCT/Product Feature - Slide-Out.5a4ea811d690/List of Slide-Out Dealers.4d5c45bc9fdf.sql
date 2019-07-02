with instore as (SELECT dpid,
  sum(case when is_in_store = true then 1 else 0 end) "In Store",
  sum(case when is_in_store = false then 1 else 0 end) "Online"
FROM fact.f_prospect 
where step_date_utc > now() - interval '6 weeks'
  and item_type in ('OrderStarted')
group by 1
)


SELECT 
       sf.success_manager AS "Success Manager",
--       sf.account_executive AS "Account Executive",
--       sf.integration_manager AS "Integration Manager",
       dp.name "Dealer Name",
       admin.properties ->> 'embedded_checkout_frame' "Slide-Out Enabled?",
       COALESCE(instore."In Store" ,0) "Instore Orders Started, past 6w",
       COALESCE(instore."Online" ,0) "Online Orders Started, past 6w",
       dp.dpid "DPID",
       to_char(sf.actual_live_date, 'yyyy-mm') "Go Live",
       sf.status "SF Status"

FROM dealer_partner_properties admin

LEFT JOIN dealer_partners dp ON admin.dealer_partner_id = dp.id -- need to convert the dealer partner number to the dpid (text)
LEFT JOIN fact.salesforce_dealer_info sf ON dp.dpid = sf.dpid -- join the salesfoce data in to get the Success Manager,etc
left join instore on instore.dpid = dp.dpid

  WHERE 
   admin.properties ->> 'embedded_checkout_frame' = 'true'
   and date = date_trunc('day',now()-interval'1 day')::date   -- Pull the most recent snapshot of Admin Properties
   and sf.status = 'Live'
   --and instore."Online" > 2  -- only look at dealers where their instore usage is > 2%

   ORDER BY COALESCE(instore."Online",0) DESC