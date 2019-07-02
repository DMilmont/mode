with instore as (SELECT 
  dpid,
  sum(case when is_in_store = true then 1 else 0 end) "In Store",
  sum(case when is_in_store = false then 1 else 0 end) "Online"
FROM fact.f_prospect 
where step_date_utc > now() - interval '6 weeks'
  and item_type in ('OrderStarted', 'Order Submitted')
group by 1
)

,tabfeature as (SELECT 
       sf.success_manager AS "Success Manager",
       sf.account_executive AS "Account Executive",
       sf.integration_manager AS "Integration Manager",
       dp.dpid "DPID",
       dp.name "Dealer Name",
       dp.primary_make "Primary Make",
       dp.state "State",
       sf.status "Status",
       admin.properties ->> 'in_store_purchase_wizard' "Feature Enabled"


FROM dealer_partner_properties admin

LEFT JOIN dealer_partners dp ON admin.dealer_partner_id = dp.id -- need to convert the dealer partner number to the dpid (text)
LEFT JOIN fact.salesforce_dealer_info sf ON dp.dpid = sf.dpid -- join the salesfoce data in to get the Success Manager,etc
left join instore on instore.dpid = dp.dpid

  WHERE 
   admin.properties ->> 'in_store_purchase_wizard' = 'false'
   and date = date_trunc('day',now()-interval'1 day')::date   -- Pull the most recent snapshot of Admin Properties
   and sf.status = 'Live'
   and instore."In Store" > 2  -- only look at dealers where their instore usage is > 2%
)

SELECT 
    sfint."DealerPartnerID__c" "DPID",
    sfint."FullDealerName__c" as "Dealer Name",
    sfc."Email",
    sfc."FirstName",
    sfc."LastName",
    sfc."Name",
    acr."Roles",
    sfint."Health_Score__c" as "Health Score",
    to_char(sfint."ActualLiveDate__c", 'YYYY_MM_DD') as "Actual Live Date",
    to_char(sfint."LastActivityDate" , 'YYYY_MM_DD') as "Last Activity Date",
    to_char(sfint."Last_Contact_Date__c", 'YYYY_MM_DD') as "Last Contact Date",
    tabfeature."Success Manager",
--    tabfeature."Account Executive",
--    tabfeature."Integration Manager",
    tabfeature."Status",
    tabfeature."Feature Enabled"

FROM roadster_salesforce."AccountContactRelation" acr

left join roadster_salesforce."Integration__c" sfint on sfint."Account__c" = acr."AccountId"
left join roadster_salesforce."Contact" sfc on sfc."Id" = acr."ContactId"
join tabfeature on tabfeature."DPID" = sfint."DealerPartnerID__c"

  where "Roles"  ilike '%integration%'
  or "Roles" ilike '%success%'
  and sfc."IsDeleted" = false
  and sfint."Status__c" = 'Live'

order by sfint."DealerPartnerID__c"



