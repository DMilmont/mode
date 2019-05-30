SELECT sum( CASE WHEN "Region"='West' THEN 1
       ELSE 0 END)                                                  as "West Count"
     ,sum( CASE WHEN "Check-In Status"='Open and Overdue' AND "Region"='West'  THEN 1
       ELSE 0 END)                                                  as "West Check-Ins Active Overdue"
       ,ROUND(100.0 * (
       sum( CASE WHEN "Check-In Status"='Currently Open' AND "Region"='West' THEN 1.0
       ELSE 0 END)            /
       sum( CASE WHEN "Region"='West' THEN 1.0
       ELSE 0 END)  ), 1)                                         as "West Not Overdue Percent"
      ,sum( CASE WHEN "Region"='East' THEN 1
       ELSE 0 END)                                                  as "East Count"
      ,sum( CASE WHEN"Check-In Status"='Open and Overdue' AND "Region"='East' THEN 1
       ELSE 0 END)                                                  as "East Check-Ins Active Overdue"
      ,ROUND(100.0 * (
       sum( CASE WHEN "Check-In Status"='Currently Open' AND "Region"='East' THEN 1.0
       ELSE 0 END)            /
       sum( CASE WHEN "Region"='East' THEN 1.0
         ELSE 0 END)  ), 1)                                       as "East Not Overdue Percent"
FROM
      (
            SELECT  US."Name"                                         as "DSM"
              ,AC."Name"                                        as "Dealer"
              ,SC."Name"                                        as "Check-In Priority"
              ,SC."Status__c"                                   as "Status"
                ,SC."Overdue__c"                                  as "Overdue"
                ,CASE WHEN date(SC."Original_Due_Date__c") < date(now()) AND SC."Status__c"='Open' then 'Open and Overdue'
                    WHEN date(SC."Original_Due_Date__c") < date(now()) AND SC."Status__c"='Completed' then 'Completed - Overdue'
                    WHEN date(SC."Original_Due_Date__c") >= date(now())AND SC."Status__c"='Open' then 'Currently Open'
                    WHEN date(SC."Original_Due_Date__c") >= date(now()) AND SC."Status__c"='Completed' then 'Completed - On Time'
                    END                                       as "Check-In Status"  
              ,date(SC."Original_Due_Date__c")                        as "Orignial Due Date"      
              ,date(SC."CreatedDate")                                 as "Created Date"
              ,date(SC."Due_Date__c" )                                as "Modified Due Date"
              ,date(SC."Completion_Date__c" )                         as "Completion Date"
              ,SC."Type_of_Contact__c"                          as "Check-In Type"

              ,CASE WHEN "East_Coast__c"='TRUE' then 'East'
                    WHEN "West_Coast__c"='TRUE' then  'West'
                    END                                         as "Region"
 
      FROM roadster_salesforce."Success_Check_Ins__c" SC
      LEFT JOIN roadster_salesforce."Account" AC on SC."Account__c"=AC."Id"
      LEFT JOIN roadster_salesforce."User" US on SC."Assigned_To__c"=US."Id"
      LEFT JOIN (select distinct "Account__c"
                 from roadster_salesforce."Integration__c"
                 where "Type__c" = 'Exclude from Rooftop Count'
                )EXC
      ON SC."Account__c"=EXC."Account__c"
      WHERE EXC."Account__c" IS NULL
      and "Status__c"='Open'
        ) A