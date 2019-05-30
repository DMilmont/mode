WITH SF_Account as (
            SELECT date(sf.actual_live_date) as "Actual Live Date"
                    ,sf.dealer_name as "Account Name"
                    ,case when sf.dealer_group is null then '-' else sf.dealer_group end as "Dealer Group"
                    ,sf.state as "Billing State/Province"
                    ,sf.account_executive AS "Account Owner: Full Name"
                    ,sf.success_manager AS "Success Owner: Full Name"
                    ,sf.integration_manager as "Integration Manager"
                    ,dp.id as dpid_id
                    ,dp.primary_make
                    ,acc."Sales_Type__c"  sales_type
            FROM fact.salesforce_dealer_info  sf
            LEFT JOIN dealer_partners dp on sf.dpid=dp.dpid
            LEFT JOIN roadster_salesforce."Account" acc on sf.sf_account_id=acc."Id"
            WHERE date(sf.actual_live_date) >= '2019-04-28'
            and acc."NPS_Survey_Sent_On__c" is null
            
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
            )        
            
SELECT "Actual Live Date"
        ,"Account Name"
        ,"Dealer Group"
        ,"Billing State/Province"
        ,a.first_name as "First Name"
        ,a.last_name as "Last Name"
        ,a.email as "Email"
        ,'Sales Agent' as "Roles"
        ,"Account Owner: Full Name"
        ,"Success Owner: Full Name"
        ,"Integration Manager"
        ,sales_type as "Sales Type"
        ,primary_make as "OEM Name"
FROM agent_detail a
INNER JOIN SF_Account sf on a.dealer_partner_id=sf.dpid_id