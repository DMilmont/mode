WITH dealer_group_closed_min_date as (
                  select O."DealerGroup__c"
                        ,dg."Name"
                      ,min(O."Start_Date_of_Current_Stage__c") as dg_close_min_date
                from roadster_salesforce."Opportunity" O
                left join roadster_salesforce."DealerGroup__c" DG
                on O."DealerGroup__c"=DG."Id"
                where O."DealerGroup__c" is not null
                and "StageName"='Closed/Won'
                group by 1,2
        ),
 detail as (select L."Id" as "Lead ID" --Lead ID
      ,case when date(L."CreatedDate")> date(L."ConvertedDate") then COALESCE(O."CreatedDate"::date AT TIME ZONE 'UTC' AT TIME ZONE 'PST',date(L."ConvertedDate") ) else COALESCE(O."CreatedDate"::date AT TIME ZONE 'UTC' AT TIME ZONE 'PST' ,L."CreatedDate") end as "Lead Timestamp" --Lead Timestamp
       ,L."Email" --Lead Email
      ,L."Type__c" as "Type"
      ,L."LeadSource" as "Lead Source"
      ,L."New_Expansion_Lead__c" as "SF New Expansion Lead"
      ,dgc."Name" as "Dealer Group"
       ,dgc.dg_close_min_date "Dealer Group Earliest Win Date"    
      ,case when L."ConvertedOpportunityId" is not null then 'Y' else 'N' end as "Opportunity" -- Opportunity Flag
      ,O."Name" --- Dealer From Opportunity
      ,case when L."ConvertedOpportunityId" is not null then L."ConvertedDate" else null end as "Opportunity Date" --Opportunity Timestamp
     ,O."StageName" as "Current Stage"
     ,"Start_Date_of_Current_Stage__c" as "Start Date of Current Stage"  

      ,case when "StageName"='Closed/Won' then 'Y' ELSE 'N' end as "Closed/Won Flag"  --- Closed Flag
      ,case when "StageName"='Closed/Won' then "Start_Date_of_Current_Stage__c" ELSE null end "Closed Timestamp"  --- Closed Timestamp
      ,case when "StageName"='Closed/Won' then ceiling("Start_Date_of_Current_Stage__c"::date - L."CreatedDate"::date) else null end as "Days to Close" --- Days to Close
     ,case when COALESCE(O."Lead_Type__c",L."Type__c") in ('Event','Marketing Qualified') then 'Marketing'
            -- when  L."LeadSource" in ('Lead Form','Event','Demo Request Form (US)') then 'MKT'   
            when COALESCE(O."Lead_Type__c",L."Type__c")   in ('OEM - Shift','OEM - Pilot','Sales','OEM_Shift','OEM - BD') then 'Sales'
            when COALESCE(O."Lead_Type__c",L."Type__c")  in ('Success','Other') then 'Other'
            when COALESCE(O."Lead_Type__c",L."Type__c")  in ('Express') then 'Demo Form'
            when COALESCE(O."Lead_Type__c",L."Type__c")  in ('Demo Request Form (US)','Demo Request Form (UK)') then 'Demo Form'
            else COALESCE(O."Lead_Type__c",L."Type__c")   end as "Lead Origination"
         
      
      ,case when "New_Expansion_Lead__c" is not null then "New_Expansion_Lead__c"
            when "New_Expansion_Lead__c" is null and dgc.dg_close_min_date is null then 'New'
            when "New_Expansion_Lead__c" is null  and dgc.dg_close_min_date="Start_Date_of_Current_Stage__c" then 'New'
             when "New_Expansion_Lead__c" is null and dgc.dg_close_min_date is not null  then 'Expansion'
        else 'ERROR' end   "New/Expansion"
      
from roadster_salesforce."Opportunity" O 
full outer join roadster_salesforce."Lead" L
on L."ConvertedOpportunityId"=O."Id"
left join dealer_group_closed_min_date dgc
on L."DealerGroup__c"=dgc."DealerGroup__c"
where COALESCE(O."CreatedDate"::date,L."CreatedDate") >='2018-01-01'
and COALESCE(L."New_Expansion_Lead__c",'x')<>'Not Applicable'
 and COALESCE(L."IsDeleted",false) is false
and case when COALESCE(L."Status",'x')='Unqualified' and "Unqualified_Reason__c"='Unresponsive' and  L."CreatedDate">='2019-07-01' then 1
        when COALESCE(L."Status",'x')='Unqualified' then 0
        else 1 end =1
)


select    date_trunc('month'::text, ("Lead Timestamp")::timestamp with time zone)   as month_date  
     --     ,"Lead Origination" as lead_origination
--          , "New/Expansion" as new_expansion
          ,count(1) as "Leads"
          ,sum(case when "Opportunity"='Y' or "Name" is not null then 1 else 0 end) as opportunity_count
          ,round(sum(case when "Opportunity"='Y' or "Name" is not null then 1 else 0 end)::decimal/count(1),2) as "Opportunity Rate" 
          ,sum(case when "Closed/Won Flag"='Y' then 1 else 0 end) as closed_won_count
          ,case when sum(case when "Opportunity"='Y' or "Name" is not null then 1 else 0 end)<>0 then round(sum(case when "Closed/Won Flag"='Y' then 1 else 0 end)::decimal / sum(case when "Opportunity"='Y' or "Name" is not null then 1 else 0 end),2) else 0 end as "Won Rate"
          
from detail         
group by 1
order by 1


