
-- Roles comes in from Sales force as a semi-colon deliminated list.  First, we need to break those into separate rows.  
with roles as (
select s.role_split, acr."Id" from roadster_salesforce."AccountContactRelation" acr, unnest(string_to_array(acr."Roles", ';')) s(role_split)
),


-- Next, we need to pull all accounts and all roles
act_roles as (
SELECT distinct  
    act."Success_Owner_Full_Name__c" "Success Manager", act."Name" "Account Name", act."Integration_Status__c" as "SF Status", role_split "Role"

FROM roadster_salesforce."AccountContactRelation" acr
left join roadster_salesforce."Account" act on act."Id" = acr."AccountId"
left join roles on acr."Id" = roles."Id" 

where acr."IsActive" = true
and acr."IsDeleted" = false
and act."IsDeleted" = false
and act."Integration_Status__c" = 'Live'

order by "Account Name"),


-- This is every Account and it's manager... we'll build off this dataset
base_data as
(
SELECT DISTINCT "Success Manager", "Account Name"
FROM act_roles
),


-- Any records Missing "Success POC" 
EB as (
  SELECT DISTINCT "Success Manager", "Account Name", "SF Status", 'MISSING' "Success POC"
  FROM act_roles 
  WHERE "Account Name" NOT IN (
  SELECT DISTINCT "Account Name"
  FROM act_roles 
  WHERE "Role"  ='Success POC')
),


-- Start with every permutation and combination of IM/Account... then link in the missing Integrations POC and GSM/GM roles
final_data as (
SELECT 
  base_data.*, 
  case when "Success POC" is Null then 'OK' else "Success POC" END "Success POC"
FROM base_data
LEFT JOIN EB ON base_data."Success Manager" = EB."Success Manager" 
                 AND base_data."Account Name" = EB."Account Name"
)

SELECT *
FROM final_data 
WHERE "Success POC" <> 'OK' 
order by "Success Manager", "Account Name"
