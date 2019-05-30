      SELECT distinct US."Name"                                         as dsm
      FROM roadster_salesforce."Success_Check_Ins__c" SC
      LEFT JOIN roadster_salesforce."Account" AC on SC."Account__c"=AC."Id"
      LEFT JOIN roadster_salesforce."User" US on SC."Assigned_To__c"=US."Id"
      LEFT JOIN (select distinct "Account__c"
                 from roadster_salesforce."Integration__c"
                 where "Type__c" = 'Exclude from Rooftop Count'
                )EXC
      ON SC."Account__c"=EXC."Account__c"
      WHERE EXC."Account__c" IS NULL
      ORDER by 1

{% form %}

dsm:
    type: select
    default: Alanna Norotsky
    options:
        labels: dsm
        values: dsm

{% endform %}
