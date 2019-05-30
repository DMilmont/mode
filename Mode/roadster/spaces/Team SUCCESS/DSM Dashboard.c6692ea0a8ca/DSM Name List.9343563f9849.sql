SELECT * 
FROM
    (
    SELECT DISTINCT success_manager,SUBSTRING(success_manager,position(' ' in success_manager)) AS Last_Name
    FROM fact.salesforce_dealer_info
    WHERE success_manager is not null
    
    UNION
    SELECT DISTINCT account_executive,SUBSTRING(account_executive,position(' ' in account_executive)) 
    FROM fact.salesforce_dealer_info
    WHERE account_executive is not null
    ) DSM_AE_List
ORDER BY success_manager

{% form %}

DSM:
    type: select
    default: 'Alanna Norotsky'
    label: Dealer Success Manager / Account Executive
    options:
        labels: success_manager
        values: success_manager

{% endform %}
