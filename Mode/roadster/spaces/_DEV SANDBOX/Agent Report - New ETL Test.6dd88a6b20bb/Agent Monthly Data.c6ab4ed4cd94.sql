-- Generates the data
with data as (SELECT am.*,
       CASE 
       WHEN "Recent Activity Timestamp" IS NULL then 'x'
       WHEN extract('day' from (now() - "Recent Activity Timestamp")) > 7 THEN 'x' 
       else '✓' END as check_for_activity
FROM report_layer.agent_report_monthly_table am
WHERE dpid = '{{ dpid }}'
)


SELECT ROW_NUMBER() OVER (ORDER BY data.dpid) Id, 
data.*,
"Agent Prospects" + "Agent Orders" + "Agent Leads" + "Shared Vehicle Details" + "Print Price Summary" + "Matched Sales" + "Total Sales (if available)" + (
   CASE 
       WHEN "Recent Activity Timestamp" IS NULL then 0
       WHEN extract('day' from (now() - "Recent Activity Timestamp")) > 7 THEN 0 
       else 1 END
) "Show Inactive Agents Only",
to_char(("Recent Activity Timestamp" at time zone timezone), 'Month DD, YYYY HH12:MIPM') timest, 
REPLACE("Certification Completed", ',', '<br>') "Completed New"

FROM data
LEFT JOIN dealer_partners dp ON data.dpid = dp.dpid