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
            WHERE date(sf.actual_live_date) <=  (date_trunc('day', now()) - INTERVAL '2 months')
            and sf.status='Live'
            
            ),
 base_agents as (
              SELECT
              a.id,
              dt
              FROM agents a
                        LEFT JOIN (
                          SELECT dt
                          FROM generate_series(current_date - '30 days'::interval, current_date, '1 day') dt
                        ) d ON 1=1
              WHERE status = 'Active'
),
            active_agents as (
            SELECT
            distinct base_agents.id,
            count (distinct month_date)
            FROM base_agents
            LEFT JOIN (
                SELECT
                DATE_TRUNC('day', gp.timestamp) month_date,
                a.id,
                sum(1) ct_pageviews
                FROM ((ga2_pageviews gp
                LEFT JOIN (
                    SELECT ga2_sessions.id, (ga2_sessions.agent_dbid) :: integer AS agent_dbid
                    FROM ga2_sessions
                    WHERE (((ga2_sessions.agent_dbid) :: text ~ '^[0-9]+$' :: text)
                    AND ga2_sessions.agent_dbid IS NOT NULL
                    AND (ga2_sessions.timestamp >= (now() - '30 days' :: interval)))
                    ) gs ON ((gp.ga2_session_id = gs.id)))
                LEFT JOIN agents a ON ((gs.agent_dbid = a.user_dbid)))
                WHERE ((a.email IS NOT NULL) AND ((gp.property) :: text <> 'Main Sites' :: text) AND
                (gp.timestamp >= (now() - '30 days' :: interval)))
                AND a.status = 'Active'
                GROUP BY 1,2
            ) dta ON base_agents.id = dta.id AND base_agents.dt = dta.month_date
            group by 1
            having count (distinct month_date)>=3            
    ),            
agent_detail as (            
            SELECT first_name
                   ,last_name 
                   ,email
                   ,dealer_partner_id
                   ,a.last_login_at
            FROM agents a
            INNER JOIN SF_Account sf on a.dealer_partner_id=sf.dpid_id
            inner join active_agents aa on a.id=aa.id
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
            where  C."Inactive__c" is not true and (
            position('Economic Buyer' in "Roles") >0
            or  position('Contract Signer' in "Roles") >0
            or  position('Integration POC' in "Roles") >0
            or  position('Success POC' in "Roles") >0
            or  position('GM' in "Roles") >0
            or  position('GSM' in "Roles") >0
            or  position('Sales Manager' in "Roles") >0
            or  position('Marketing Contact' in "Roles") >0
            or  position('Finance Office POC' in "Roles") >0
            )             and (position('Economic Decision Maker' in "Roles") = 0
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


        ,'Past 30 Day Login' as "Login Date Selection"
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
   
        , CASE 
        WHEN a.last_login_at > (date_trunc('day', now()) - '31 days'::interval) THEN 'Past 30 Day Login'
        WHEN a.last_login_at > (date_trunc('day', now()) - '61 days'::interval) THEN 'Past 60 Day Login'
        WHEN a.last_login_at > (date_trunc('day', now()) - '91 days'::interval) THEN 'Past 90 Day Login'
        ELSE 'Older' END as "Login Date Selection"
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