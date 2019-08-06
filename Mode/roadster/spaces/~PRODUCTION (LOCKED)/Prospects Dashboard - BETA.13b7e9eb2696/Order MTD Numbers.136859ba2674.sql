-- Generate Order and Prospect Ratio Information
with base_data as (
SELECT *
FROM fact.agg_mtd_prospects
WHERE dpid = '{{ dpid }}' 
 AND dpsk = '{{ dpsk }}'
)

SELECT 
month_year,
dpid,
SUM(CASE WHEN 
    item_type = 'All' and grade = 'All' 
    and is_in_store IS Null 
    and is_prospect_close_sale IS Null
    and source = 'Order Step'
    then email_count end) "Total Orders",
SUM(CASE WHEN 
    item_type = 'All' and grade = 'All' 
    and is_in_store is false
    and is_prospect_close_sale IS Null
    and source = 'Order Step'
    then email_count end) "Online Orders",
SUM(CASE WHEN 
    item_type = 'All' and grade = 'All' 
    and is_in_store is false
    and is_prospect_close_sale IS Null
    and source = 'Lead Type'
    then email_count end) "Online Prospects",
    
  ROUND(SUM(CASE WHEN 
    item_type = 'All' and grade = 'All' 
    and is_in_store is false
    and is_prospect_close_sale IS Null
    and source = 'Order Step'
    then email_count end)::decimal / 
  SUM(CASE WHEN 
    item_type = 'All' and grade = 'All' 
    and is_in_store is false
    and is_prospect_close_sale IS Null
    and source = 'Lead Type'
    then email_count end), 4) "Order Ratio"

FROM base_data
GROUP BY month_year, dpid
ORDER BY month_year