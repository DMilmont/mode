-- Generates the data
with data as (SELECT am.*,
       CASE 
       WHEN "Recent Activity Timestamp" IS NULL then 'x'
       WHEN extract('day' from (now() - "Recent Activity Timestamp")) > 7 THEN 'x' 
       else '✓' END as check_for_activity
FROM report_layer.agent_report am
WHERE dpid = '{{ dpid }}'
AND "Start Date of Metrics" = (SELECT max("Start Date of Metrics") FROM report_layer.agent_report)
)

SELECT ROW_NUMBER() OVER (ORDER BY dpid) Id, 
data.*,
REPLACE("Certification Completed", ',', '<br>') "Completed New"
FROM data