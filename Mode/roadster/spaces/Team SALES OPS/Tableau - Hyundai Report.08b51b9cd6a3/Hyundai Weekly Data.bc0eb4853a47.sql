with base_data as (
SELECT *
FROM report_layer.shopper_assurance_program_kpis
WHERE date >= '{{ start_date }}' and date <= '{{ end_date }}'
),

almost_data as (

SELECT
dpid, 
COUNT(DISTINCT CASE WHEN item_type = 'Total Visitor' AND SOURCE = 'Traffic' THEN unique_visitor_id ELSE NULL END) "Tier 3 Visitors",
COUNT(DISTINCT CASE WHEN item_type = 'Tier 3 Leads' AND SOURCE = 'Lead Type' THEN unique_visitor_id ELSE NULL END) "Tier 3 Leads",
COUNT(DISTINCT CASE WHEN item_type = 'TestDrive' THEN unique_visitor_id ELSE NULL END) "Test Drive Leads",
COUNT(DISTINCT CASE WHEN is_in_store = 'false' AND item_type = 'Express Credit App Visitor' THEN unique_visitor_id ELSE NULL END) "Finance App Started",
COUNT(DISTINCT CASE WHEN is_in_store = 'false' AND (item_type = 'CreditPreApprovalInquiry' or item_type = 'Credit Completed') THEN unique_visitor_id ELSE NULL END) "Finance App Completed",
COUNT(DISTINCT CASE WHEN (item_type = 'StandaloneTrade' or item_type = 'Trade-In Attached' or item_type = 'TradeEstimate') THEN unique_visitor_id ELSE NULL END) "Trade-In Started",
COUNT(DISTINCT CASE WHEN is_in_store = 'false' and source = 'Order Step' and item_type = 'Trade-In Attached' THEN unique_visitor_id ELSE NULL END) "Trade-In Completed",
COUNT(DISTINCT CASE WHEN item_type = 'Express VDP Visitor' and source = 'Traffic' THEN unique_visitor_id ELSE NULL END) "Express VDP Visitors",
COUNT(DISTINCT CASE WHEN is_in_store = 'false' and source = 'Sales' and item_type = 'Roadster Sales (Cohort)' THEN unique_visitor_id ELSE NULL END) "Cars Sold Online",
COUNT(DISTINCT CASE WHEN is_in_store = 'true' and source = 'Sales' and item_type = 'Roadster Sales (Cohort)' THEN unique_visitor_id ELSE NULL END) "Cars Sold In-Store",
max(nps) "NPS"
FROM base_data
GROUP BY 1
)

SELECT almost_data.*, 
dp.name, 
hsa.dealer_code,
"Cars Sold Online" + "Cars Sold In-Store" "Total Cars Sold",
'Past 7 Days of Data' "Title"
FROM almost_data
LEFT JOIN dealer_partners dp ON almost_data.dpid = dp.dpid
LEFT JOIN fact.hyundai_shopper_assurance hsa ON almost_data.dpid = hsa.dpid
WHERE hsa.shopper_assurance = 'Y'