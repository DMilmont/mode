SELECT *
FROM george_personal.daily_credit_usage 
WHERE dpid = '{{ dpid }}'
AND days < Current_Date