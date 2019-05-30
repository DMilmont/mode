 with instore as (SELECT dpid,
  sum(case when is_in_store = true then 1 else 0 end) "In Store",
  sum(case when is_in_store = false then 1 else 0 end) "Online"
FROM fact.f_prospect 
where step_date_utc > now() - interval '6 weeks'
  and item_type in ('OrderStarted', 'Order Submitted')
group by 1
)


SELECT 
       sf.success_manager AS "Success Manager",
--       sf.account_executive AS "Account Executive",
--       sf.integration_manager AS "Integration Manager",
       dp.name "Dealer Name",
       to_char(sf.actual_live_date, 'yyyy-mm') "Go Live",
       sf.status "SF Status",
       instore."In Store" "In Store Orders",
       instore."Online" "Online Orders",
       admin.properties ->> 'in_store_purchase_wizard' "In-Store Wizard Enabled?",
       dp.dpid "DPID"

FROM dealer_partner_properties admin

LEFT JOIN dealer_partners dp ON admin.dealer_partner_id = dp.id -- need to convert the dealer partner number to the dpid (text)
LEFT JOIN fact.salesforce_dealer_info sf ON dp.dpid = sf.dpid -- join the salesfoce data in to get the Success Manager,etc
left join instore on instore.dpid = dp.dpid

  WHERE 
   admin.properties ->> 'in_store_purchase_wizard' = 'false'
   and date = date_trunc('day',now()-interval'1 day')::date   -- Pull the most recent snapshot of Admin Properties
   and sf.status = 'Live'
   and instore."In Store" > 2  -- only look at dealers where their instore usage is > 2%

   ORDER BY instore."In Store" DESC
