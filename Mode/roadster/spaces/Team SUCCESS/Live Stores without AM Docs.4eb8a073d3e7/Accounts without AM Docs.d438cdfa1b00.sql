-- Returns first 100 rows from roadster_salesforce.Account
with ct as (SELECT "Success_Owner_Full_Name__c" as success_owner
,count("Name") as act_cnt
FROM roadster_salesforce."Account" 
where "AM_Notes_Quip_Doc__c" is NULL
and "Status_Formula__c" = 'Live'
group by 1)


SELECT  '(' || to_char( ct.act_cnt , '00') || ') ' || coalesce("Success_Owner_Full_Name__c",'<Not Assigned>') as "Success Owner"
,"Name" as "Account Name"
FROM roadster_salesforce."Account" sf 
left join ct on ct.success_owner = sf."Success_Owner_Full_Name__c"
where "AM_Notes_Quip_Doc__c" is NULL
and "Status_Formula__c" = 'Live'
order by 1 desc, 2