with filter_for_dpids as (
  -- Generate the Dealer Group associated with the dpid param filter
  -- Sets up the entire query. Needs the dpsk and the dpid from params to work
  SELECT DISTINCT CASE WHEN di.dealer_group IS NULL THEN dealer_name ELSE di.dealer_group END dealer_group
  FROM fact.salesforce_dealer_info di
  INNER JOIN public.dealer_partners dp on di.dpid = dp.dpid
  WHERE set_dealer IS TRUE 
),

base_percentile_data as (
    SELECT dpid, percent_rank() OVER (ORDER BY score) keep_dpids
    FROM fact.f_benchmark b
    WHERE end_month = (SELECT max(end_month) from fact.f_benchmark)
    ORDER BY percent_rank() OVER (ORDER BY score) desc
),

percentile_dpids as (

    SELECT DISTINCT 90 percentile, dpid
    FROM base_percentile_data
    WHERE keep_dpids >= .90

    UNION

    SELECT DISTINCT 75 percentile, dpid
    FROM base_percentile_data
    WHERE keep_dpids >= .75

    UNION

    SELECT DISTINCT 50 percentile, dpid
    FROM base_percentile_data
    WHERE keep_dpids >= .50

    ORDER BY percentile, dpid
  ), 
  
 percent_dpids as ( 
SELECT percentile_dpids.*,
       '' || percentile_dpids.percentile::text || 'th Percentile Dealer Groups' "name",
       'All' primary_make
FROM percentile_dpids
),


filter_for_dealer_group  as (
SELECT DISTINCT dp.dpid
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE CASE WHEN dealer_group IS NULL THEN dealer_name ELSE dealer_group END IN (SELECT * FROM filter_for_dpids)
AND dp.status = 'Live'
--and dealer_group <> dp.name
), 

base_agent_data as (
SELECT DISTINCT dp.name, a.first_name, a.last_name, a.email
FROM agents a 
LEFT JOIN dealer_partners dp ON a.dealer_partner_id = dp.id
where dp.dpid IN (SELECT * FROM filter_for_dealer_group)
AND a.status = 'Active'
)


SELECT DISTINCT 
bad.name "Rooftop",
bad.email "Email",
initcap(bad.first_name) || ' ' || left(initcap(bad.last_name), 1) "Agent Name",
acd.training_type "Roadster Certifications",
CASE WHEN acd.training_type IS NULL THEN 0 ELSE 1 END "Any Roadster Certifications"
FROM base_agent_data bad 
LEFT JOIN public.agent_certifications_data acd ON bad.email = acd.email
WHERE bad.name <> 'Lexus of Pleasanton'