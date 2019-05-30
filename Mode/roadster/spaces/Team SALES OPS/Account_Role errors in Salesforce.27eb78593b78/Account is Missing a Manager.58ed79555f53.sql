-- If any of the managers are missing, replace the blank cell with MISSING
SELECT distinct act."Name" "Account Name",
                "Integration_Status__c" AS "SF Status",
                CASE
                    WHEN "Integration_Manager__c" is Null then 'MISSING'
                    ELSE "Integration_Manager__c"
                END "Integration Manager",
                CASE
                    WHEN "Account_Owner_Full_Name__c" is Null then 'MISSING'
                    ELSE "Account_Owner_Full_Name__c"
                END "Account Executive",
                CASE
                    WHEN "Success_Owner_Full_Name__c" is NULL then 'MISSING'
                    ELSE "Success_Owner_Full_Name__c"
                END "Success Manager"
FROM roadster_salesforce."AccountContactRelation" acr

-- Bring in the key account information
left join roadster_salesforce."Account" act
  ON act."Id" = acr."AccountId"

-- Only show active accounts
WHERE acr."IsActive" = true
  AND acr."IsDeleted" = false
  AND act."IsDeleted" = false
  AND "Integration_Status__c" = 'Live'

-- find instances where key managers are 'null' or set to the default (admin user)
  AND ("Account_Owner_Full_Name__c" IS NULL
       OR "Integration_Manager__c" is null
       OR act."Success_Owner_Full_Name__c" is null
       OR act."Success_Owner_Full_Name__c" = 'Admin User'
       OR "Integration_Manager__c" = 'Admin User'
       OR "Account_Owner_Full_Name__c" = 'Admin User')

ORDER BY "Account Name" ;

