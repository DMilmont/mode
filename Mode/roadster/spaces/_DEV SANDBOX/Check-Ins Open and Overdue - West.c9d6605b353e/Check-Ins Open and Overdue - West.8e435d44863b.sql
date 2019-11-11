      SELECT  US."Name"                                         as "DSM"
              ,AC."Name"                                        as "Dealer"
              ,SC."Name"                                        as "Check-In Priority"
              ,SC."Status__c"                                   as "Status"
                ,SC."Overdue__c"                                  as "Overdue"
       ,CASE WHEN date(SC."Original_Due_Date__c") > date(now() AT TIME ZONE 'UTC' AT TIME ZONE 'PST')    AND SC."Status__c"='Open' then 'Currently Open'
                    WHEN date(SC."Original_Due_Date__c") < date(SC."Completion_Date__c" )   AND SC."Status__c"='Completed' then 'Completed - Overdue'
                    WHEN date(SC."Original_Due_Date__c") <= date(now() AT TIME ZONE 'UTC' AT TIME ZONE 'PST')   AND SC."Status__c"='Open' then 'Open and Overdue'
                    WHEN date(SC."Original_Due_Date__c") >= date(SC."Completion_Date__c" ) AND SC."Status__c"='Completed' then 'Completed - On Time'
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
                
            AND  CASE WHEN date(SC."Original_Due_Date__c") > date(now() AT TIME ZONE 'UTC' AT TIME ZONE 'PST')    AND SC."Status__c"='Open' then 'Currently Open'
                    WHEN date(SC."Original_Due_Date__c") < date(SC."Completion_Date__c" )   AND SC."Status__c"='Completed' then 'Completed - Overdue'
                    WHEN date(SC."Original_Due_Date__c") <= date(now() AT TIME ZONE 'UTC' AT TIME ZONE 'PST')   AND SC."Status__c"='Open' then 'Open and Overdue'
                    WHEN date(SC."Original_Due_Date__c") >= date(SC."Completion_Date__c" ) AND SC."Status__c"='Completed' then 'Completed - On Time'
                    END ='Open and Overdue'
                        and SC."IsDeleted" is false
                        and "Check_In_Type__c"='Success Check-In'
                                and date(SC."Original_Due_Date__c") >='2019-09-01'
            and date(SC."Original_Due_Date__c") <date(now() AT TIME ZONE 'UTC' AT TIME ZONE 'PST')
      ORDER BY SC."Original_Due_Date__c",US."Name",AC."Name"              