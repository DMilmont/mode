      SELECT  US."Name"                                         as "DSM"
              ,AC."Name"                                        as "Dealer"
              ,SC."Name"                                        as "Check-In Priority"
              ,SC."Status__c"                                   as "Status"
                ,SC."Overdue__c"                                  as "Overdue"
                ,CASE WHEN sc."Overdue__c"='TRUE' AND SC."Status__c"='Open' then 'Open and Overdue'
                    WHEN sc."Overdue__c"='TRUE' AND SC."Status__c"='Completed' then 'Completed - Overdue'
                    WHEN sc."Overdue__c"='FALSE' AND SC."Status__c"='Open' then 'Open Check-In TBD'
                    WHEN sc."Overdue__c"='FALSE' AND SC."Status__c"='Completed' then 'Completed - On Time'
                    END                                       as "Check-In Status"  
              ,date(SC."Original_Due_Date__c")                        as "Orignial Due Date"      
              ,date(SC."CreatedDate")                                 as "Created Date"
              ,date(SC."Due_Date__c")                                 as "Modified Due Date"

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
            AND "West_Coast__c"='TRUE' 
            AND CASE WHEN sc."Overdue__c"='TRUE' AND SC."Status__c"='Open' then 'Open and Overdue'
                    WHEN sc."Overdue__c"='TRUE' AND SC."Status__c"='Completed' then 'Completed - Overdue'
                    WHEN sc."Overdue__c"='FALSE' AND SC."Status__c"='Open' then 'Open Check-In TBD'
                    WHEN sc."Overdue__c"='FALSE' AND SC."Status__c"='Completed' then 'Completed - On Time'
                    END    ='Open and Overdue'
      ORDER BY SC."Original_Due_Date__c",US."Name",AC."Name"              