WITH SF_Account as (
            SELECT date(sf.actual_live_date) as "Actual Live Date"
                    ,sf.dealer_name as "Account Name"
                    ,case when sf.dealer_group is null then '-' else sf.dealer_group end as "Dealer Group"
                    ,sf.state as "Billing State/Province"
                    ,sf.account_executive AS "Account Owner: Full Name"
                    ,acc."Success_Owner_Full_Name__c" AS "Success Owner: Full Name"
                    ,acc."Integration_Manager__c" as "Integration Manager"
                    ,dp.id as dpid_id
                    ,dp.primary_make
                    ,i."OEM_Names__c" as oem_name
                    ,acc."Sales_Type__c"  sales_type
                    ,sf.sf_account_id as sf_account_id
            FROM fact.salesforce_dealer_info  sf
            LEFT JOIN dealer_partners dp on sf.dpid=dp.dpid
            LEFT JOIN roadster_salesforce."Account" acc on sf.sf_account_id=acc."Id"
             LEFT JOIN roadster_salesforce."Integration__c" i on acc."Id"=i."Account__c"
            WHERE date(sf.actual_live_date) >= '2019-04-28'
            and acc."NPS_Survey_Sent_On__c" is  null
            
            ),
            
agent_detail as (            
            SELECT first_name
                   ,last_name 
                   ,email
                   ,dealer_partner_id
            FROM agents a
            INNER JOIN SF_Account sf on a.dealer_partner_id=sf.dpid_id
            WHERE a.status='Active'
            AND email not like '%roadster%'
            ),
key_contact_detail as  (
            SELECT "FirstName" as first_name
                  ,"LastName" as last_name
                  ,"Email" as email
                  ,ACR."AccountId" as sf_account_id
                  ,ACR."Roles" as roles
            FROM  roadster_salesforce."AccountContactRelation" ACR
            left join roadster_salesforce."Contact" C on ACR."ContactId"=c."Id"
            INNER JOIN SF_account sf on ACR."AccountId"=sf.sf_account_id
            where (position('Economic Buyer' in "Roles") >0
            or  position('Contract Signer' in "Roles") >0
            or  position('Integration POC' in "Roles") >0
            or  position('Success POC' in "Roles") >0
            or  position('GM' in "Roles") >0
            or  position('GSM' in "Roles") >0
            or  position('Sales Manager' in "Roles") >0
            or  position('Marketing Contact' in "Roles") >0
            or  position('Finance Office POC' in "Roles") >0)
            and (position('Economic Decision Maker' in "Roles") = 0
                  and position('Executive Sponsor' in "Roles")=0
                  and position('Decision Maker' in "Roles")=0
                  and position('Other' in "Roles")=0
                  and position('Technical Buyer' in "Roles")=0
                  and position('Business User' in "Roles")=0
                  and position('Influencer' in "Roles")=0
                  and position('Evaluator' in "Roles")=0
                  and position('Internet Director' in "Roles")=0
                  and position('Pre-owned Manager' in "Roles")=0
                  and position('Dealer IT Contact' in "Roles")=0
                  and position('Website Provider Contact' in "Roles")=0
                  and position('DNS Support' in "Roles")=0
                  and position('Legal Contact' in "Roles")=0
                  and position('Dealer Ad Compliance Contact' in "Roles")=0
                  and position('OEM Ad Compliance Contact' in "Roles")=0
                  and position('F&I Contact' in "Roles")=0
                  and position('Roadster Executive Sponsor' in "Roles")=0
                  and position('Digital/Website Contact' in "Roles")=0
                    )
)          

SELECT "Actual Live Date"
        ,"Account Name"
        ,"Dealer Group"
        ,"Billing State/Province"
        ,a.first_name as "First Name"
        ,a.last_name as "Last Name"
        ,a.email as "Email"
        ,roles as "Roles"
        ,coalesce("Account Owner: Full Name",'-') as "Account Owner: Full Name"
        ,coalesce("Success Owner: Full Name",'-') as "Success Owner: Full Name"
        ,coalesce("Integration Manager",'-') as "Integration Manager"
        ,coalesce(sales_type ,'-') as "Sales Type"
        ,coalesce(oem_name ,'-') as "OEM Name"
        ,case when roles like '%Economic Buyer%' then 'True' ELSE 'False' end "IsEconomicBuyer"
        ,case when roles like '%Contract Signer%' then 'True' ELSE 'False' end "IsContractSigner"
        ,case when roles like '%Finance Office POC%' then 'True' ELSE 'False' end "IsFinanceOfficePOC"
        ,case when roles like '%GM%' then 'True' ELSE 'False' end "IsGeneralManager"
        ,case when roles like '%GSM%' then 'True' ELSE 'False' end "IsGeneralSalesManager"
        ,case when roles like '%Sales Manager%' then 'True' ELSE 'False' end "IsSalesManager"  
        ,case when roles like '%Integration POC%' then 'True' ELSE 'False' end "IsIntegrationPOC"
        ,case when roles like '%Success POC%' then 'True' ELSE 'False' end "IsSuccessPOC"  
        ,case when roles like '%Marketing Contact%' then 'True' ELSE 'False' end "IsMarketingContact"
        ,case when roles like '%Sales Agent%' then 'True' ELSE 'False' end "IsSalesAgent"
        ,case when roles like '%Billing Contact%' then 'True' ELSE 'False' end "IsBillingContact"
        ,'True' as "IsKeyContact"
FROM key_contact_detail a
INNER JOIN SF_Account sf on a.sf_account_id=sf.sf_account_id


UNION
            
SELECT "Actual Live Date"
        ,"Account Name"
        ,"Dealer Group"
        ,"Billing State/Province"
        ,a.first_name as "First Name"
        ,a.last_name as "Last Name"
        ,a.email as "Email"
        ,'Sales Agent' as "Roles"
        ,coalesce("Account Owner: Full Name",'-') as "Account Owner: Full Name"
        ,coalesce("Success Owner: Full Name",'-') as "Success Owner: Full Name"
        ,coalesce("Integration Manager",'-') as "Integration Manager"
        ,coalesce(sales_type ,'-') as "Sales Type"
        ,coalesce(oem_name ,'-') as "OEM Name"
        ,'False' as IsEconomicBuyer
        ,'False' as IsContractSigner
        ,'False' as IsFinanceOfficePOC
        ,'False' as IsGeneralManager
        ,'False' as IsGeneralSalesManager
        ,'False' as IsSalesManager  
        ,'False' as IsIntegrationPOC
        ,'False' as IsSuccessPOC  
        ,'False' as IsMarketingContact
        ,'True' as IsSalesAgent
        ,'False' as IsBillingContact
        ,'False' as IsKeyContact
FROM agent_detail a
INNER JOIN SF_Account sf on a.dealer_partner_id=sf.dpid_id
LEFT join key_contact_detail kcd on a.email=kcd.email
where kcd.email is null