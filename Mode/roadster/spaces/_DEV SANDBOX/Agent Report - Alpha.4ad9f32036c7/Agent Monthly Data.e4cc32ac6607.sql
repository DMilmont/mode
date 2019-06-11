-- Generates the data
SELECT *
FROM fact.agg_agent_report_monthly
WHERE dpid = '{{ dpid }}'