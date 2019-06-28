-- Generates the data
SELECT am.*,
       CASE 
       WHEN "Recent Activity Timestamp" IS NULL then 'x'
       WHEN extract('day' from (now() - "Recent Activity Timestamp")) > 7 THEN 'x' 
       else '✓' END as check_for_activity
FROM report_layer.agent_report am
WHERE dpid = '{{ dpid }}'