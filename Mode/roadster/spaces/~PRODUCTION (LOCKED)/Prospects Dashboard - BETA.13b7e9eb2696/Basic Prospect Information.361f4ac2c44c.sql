WITH 
agent_prospects AS (
   SELECT
   f.customer_email,
   f.dpid,
   f.dpsk,
   user_id,
   'All Prospects' "type",
   1 exists_now,
   max(f.cohort_date_utc) dt
   FROM fact.f_prospect f
   WHERE
   dpid = '{{ dpid }}'
   AND dpsk = {{ dpsk }}
   AND f.cohort_date_utc >= (date_trunc('month', now()) - '5 months'::interval)
   GROUP BY 1,2,3,4,5,6, date_trunc('month' :: text, (f.cohort_date_utc) :: timestamp with time zone)
  ),

online_prospects AS (
   SELECT
   f.customer_email,
   f.dpid,
   f.dpsk,
   user_id,
   'Online Prospects' "type",
   1 exists_now,
   max(f.cohort_date_utc) dt
   FROM fact.f_prospect f
   WHERE
   dpid = '{{ dpid }}'
  AND dpsk = {{ dpsk }}
   AND is_in_store = true
   AND f.cohort_date_utc >= (date_trunc('month', now()) - '5 months'::interval)
   GROUP BY 1,2,3,4,5,6, date_trunc('month' :: text, (f.cohort_date_utc) :: timestamp with time zone)

  ),
  
instore_prospects AS (
   SELECT
   f.customer_email,
   f.dpid,
   f.dpsk,
   user_id,
   'In-Store Prospects' "type",
   1 exists_now,
   max(f.cohort_date_utc) dt
   FROM fact.f_prospect f
   WHERE
   dpid = '{{ dpid }}'
  AND dpsk = {{ dpsk }}
   AND is_in_store <> true
   AND f.cohort_date_utc >= (date_trunc('month', now()) - '5 months'::interval)
   GROUP BY 1,2,3,4,5,6, date_trunc('month' :: text, (f.cohort_date_utc) :: timestamp with time zone)
  ),
  
express_visitors as (
   SELECT
   (distinct_id)::text customer_email,
   dpid, 
   dpsk,
   NULL::integer user_id,
   'Express Visitors' "type",
   1 "exists_now",
   max(date) dt
   FROM fact.f_traffic
   WHERE 
   dpid = '{{ dpid }}'
 AND dpsk = {{ dpsk }}
   AND  f_traffic.date >= (date_trunc('month', now()) - '5 months'::interval)
   GROUP BY 1,2,3,4,5,6,
   (date_trunc('month' :: text, (f_traffic.date) :: timestamp with time zone))

),



almost as (
  
  
SELECT *
FROM agent_prospects
UNION 
SELECT *
FROM online_prospects
UNION 
SELECT *
FROM instore_prospects
UNION 
SELECT 
customer_email::text,
dpid, 
dpsk,
user_id,
"type",
"exists_now",
dt
FROM express_visitors
)

-- https://dealers.roadster.com/longolexus/user_contacts?search=asif%20paul

SELECT almost.*, 
to_char(dt, 'Month YYYY') mth_yr,
u.email "Customer Email", 
initcap(u.first_name || ' ' || u.last_name) "Customer Name",
'https://dealers.roadster.com/' || dpid || '/user_contacts?search=' || initcap(u.first_name) || '%20' || initcap(u.last_name)  lead_url
FROM almost
LEFT JOIN users u ON almost.user_id = u.id