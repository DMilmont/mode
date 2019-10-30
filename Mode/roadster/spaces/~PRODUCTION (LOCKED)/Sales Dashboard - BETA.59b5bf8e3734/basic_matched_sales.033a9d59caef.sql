
WITH prospects as (
SELECT date_trunc('month', cohort_date_utc) month_year,
COUNT(DISTINCT customer_email) ct_prospects
FROM fact.f_prospect
WHERE dpid = '{{ dpid }}'
AND dpsk = '{{ dpsk }}'
GROUP BY 1
),

matched_sales as (
SELECT (date_trunc('month' :: text,
                    ((f_sale.first_lead_timestamp) :: date) :: timestamp with time zone)) AS month_year,
         --f_sale.first_is_in_store                                                        AS is_in_store,
         count(DISTINCT
           CASE
             WHEN (f_sale.first_email IS NOT NULL) THEN f_sale.first_email
             ELSE f_sale.vin
               END)                                                                      AS ct_matched_sales
  FROM fact.f_sale
  WHERE (f_sale.days_to_close_from_first_lead < (91) :: double precision)
  AND dpid = '{{ dpid }}'
  AND dpsk = '{{ dpsk }}'
  GROUP BY 1
),

base_data as (
SELECT *
FROM fact.d_cal_month
ORDER BY month_year desc

)

SELECT p.*, 
ct_prospects "Total Unique Prospects",
ct_matched_sales "Total Matched Sales (90 Days)",
(ct_matched_sales::decimal / ct_prospects) "90 Day Close Rate"
FROM prospects p 
LEFT JOIN matched_sales ms ON p.month_year = ms.month_year 
ORDER BY month_year desc