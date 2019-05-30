
-- Roles comes in from Sales force as a semi-colon deliminated list.  First, we need to break those into separate rows.  
with roles as (
select s.role_split, acr."Id" from roadster_salesforce."AccountContactRelation" acr, unnest(string_to_array(acr."Roles", ';')) s(role_split)
),

-- Next, we need to pull all accounts and all roles
act_roles as (
SELECT distinct  
    act."Integration_Manager__c" "Integration Manager", act."Name" "Account Name", act."Integration_Status__c" as "SF Status", role_split "Role"

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
SELECT DISTINCT "Integration Manager", "Account Name"
FROM act_roles
),



-- Any records Missing "Integrations POC" 
IntPOC as (
  SELECT DISTINCT "Integration Manager", "Account Name", "SF Status", 'MISSING' "Integration POC"
  FROM act_roles 
  WHERE "Account Name" NOT IN (
  SELECT DISTINCT "Account Name"
  FROM act_roles 
  WHERE "Role"  ='Integration POC')
),

-- Any records Missing ("GSM" AND "GM")
GSM as (
  SELECT DISTINCT "Integration Manager", "Account Name", "SF Status", 'BOTH MISSING' "GSM/GM"
  FROM act_roles 
  WHERE "Account Name" NOT IN (
  SELECT DISTINCT "Account Name"
  FROM act_roles 
  WHERE "Role"  ='GSM' or "Role" = 'GM')
),


-- Start with every permutation and combination of IM/Account... then link in the missing Integrations POC and GSM/GM roles
final_data as (
SELECT 
  base_data.*, 
  case when "Integration POC" is Null then 'OK' else "Integration POC" END "Integration POC",
  case when "GSM/GM" is Null then 'OK' else "GSM/GM" END "GSM/GM"
FROM base_data
LEFT JOIN IntPOC ON base_data."Integration Manager" = IntPOC."Integration Manager" 
                 AND base_data."Account Name" = IntPOC."Account Name"
LEFT JOIN GSM ON base_data."Integration Manager" = GSM."Integration Manager" 
                 AND base_data."Account Name" = GSM."Account Name"
)

SELECT *
FROM final_data 
WHERE "Integration POC" <> 'OK' OR "GSM/GM" <> 'OK'
order by "Integration Manager", "Account Name"
