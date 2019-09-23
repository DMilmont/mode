WITH tab1 as (
SELECT DISTINCT "Data Year", "Data Month", "Month & Year"
FROM report_layer.agent_report am
ORDER BY "Data Year", "Data Month"
)

SELECT 
"Month & Year"
FROM tab1
