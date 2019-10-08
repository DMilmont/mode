SELECT
dpid,
CASE 
  WHEN "CDK" = 1 AND "Dealer Socket" = 1 THEN 'CDK & DealerSocket'
  WHEN "CDK" = 1 AND "Dealer Socket" = 0 THEN 'CDK'
  WHEN "CDK" = 0 AND "Dealer Socket" = 1 THEN 'DealerSocket'
  ELSE '' END AS "DMS Type"
FROM (

SELECT
dpid,
SUM("CDK") "CDK",
SUM("Dealer Socket") "Dealer Socket"
FROM (
    SELECT
    DISTINCT
    dpid,
    CASE
      WHEN crm_type = 'cdk' THEN 1 else 0 END "CDK",

    CASE
      WHEN crm_type = 'dealer-socket' THEN 1 else 0 END "Dealer Socket"
    FROM crm_records crm
    LEFT JOIN dealer_partners dp ON crm.dealer_partner_id = dp.id
    WHERE sold_at >= (NOW() - '30 days'::interval)
    AND dpid = '{{ dpid }}'
    AND dp.tableau_secret = '{{ dpsk }}'
) t
GROUP BY 1
) v