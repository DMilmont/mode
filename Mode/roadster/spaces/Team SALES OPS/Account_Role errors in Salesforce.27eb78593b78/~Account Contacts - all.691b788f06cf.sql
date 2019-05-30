
-- Roles comes in from Sales force as a semi-colon deliminated list.  First, we need to break those into separate rows.  
with roles as (
select s.role_split, acr."Id" from roadster_salesforce."AccountContactRelation" acr, unnest(string_to_array(acr."Roles", ';')) s(role_split)
)


SELECT distinct  
    act."Name" "Account Name", role_split "Role", sfc."Name" "Contact Name", "Account_Owner_Full_Name__c" "Account Executive", "Integration_Manager__c" "Integration Manager", act."Success_Owner_Full_Name__c" "Success Manager"

FROM roadster_salesforce."AccountContactRelation" acr
left join roadster_salesforce."Account" act on act."Id" = acr."AccountId"
left join roles on acr."Id" = roles."Id" 
left join roadster_salesforce."Contact" sfc on acr."ContactId" = sfc."Id"

where acr."IsActive" = true
and acr."IsDeleted" = false
and act."IsDeleted" = false
and "Integration_Status__c" = 'Live'

order by "Account Name", "Role"
;
