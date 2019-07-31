
WITH prospects as (
SELECT date_trunc('month', cohort_date_utc) month_year,
is_in_store,
COUNT(DISTINCT customer_email) ct_prospects
FROM fact.f_prospect
WHERE dpid = '{{ dpid }}'
GROUP BY 1, 2
),

matched_sales as (
SELECT date_trunc('month' :: text,
                    ((f_sale.first_lead_timestamp) :: date) :: timestamp with time zone) AS month_year,
         f_sale.first_is_in_store                                                        AS is_in_store,
         count(DISTINCT
           CASE
             WHEN (f_sale.first_email IS NOT NULL) THEN f_sale.first_email
             ELSE f_sale.vin
               END)                                                                      AS ct_matched_sales
  FROM fact.f_sale
  WHERE (f_sale.days_to_close_from_first_lead < (91) :: double precision)
  AND dpid = '{{ dpid }}'
  GROUP BY 1,2
),

base_data as (
SELECT *
FROM fact.d_cal_month
LEFT JOIN (
  SELECT true is_in_store
  UNION
  SELECT false is_in_store
) t ON 1=1
ORDER BY month_year desc

)

SELECT p.*, 
(p.month_year + '1 day'::interval) mth_yr,
CASE WHEN p.is_in_store = TRUE THEN 'In-Store' ELSE 'Online' END in_store_flag,
'Matched Sales Summary' title,
ct_prospects "Total Unique Prospects",
ct_matched_sales "Total Matched Sales (90 Days)",
(ct_matched_sales::decimal / ct_prospects) "90 Day Close Rate"
FROM prospects p 
LEFT JOIN matched_sales ms ON p.month_year = ms.month_year AND p.is_in_store = ms.is_in_store
ORDER BY month_year desc