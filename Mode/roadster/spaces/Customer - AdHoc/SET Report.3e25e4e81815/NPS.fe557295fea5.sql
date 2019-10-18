WITH rolling_nps as (
SELECT dp.name,
             count(
               CASE
                 WHEN (r.recommend >= 9) THEN r.dealer_partner_id
                 ELSE NULL :: integer
                   END) AS rolling_promoters,
             count(
               CASE
                 WHEN (r.recommend <= 6) THEN r.dealer_partner_id
                 ELSE NULL :: integer
                   END) AS rolling_detractors,
             count(
               CASE
                 WHEN (r.recommend IS NOT NULL) THEN r.dealer_partner_id
                 ELSE NULL :: integer
                   END) AS rolling_total_reviews
      FROM (rating r
          JOIN dealer_partners dp ON ((dp.id = r.dealer_partner_id)))
      WHERE r.timestamp >= date_trunc('day', now()) - '60 days'::interval
      AND 
      r.timestamp < date_trunc('day', now())
      GROUP BY dp.name

),

lifetime as (
SELECT dp.name ,
             count(
               CASE
                 WHEN (r.recommend >= 9) THEN r.dealer_partner_id
                 ELSE NULL :: integer
                   END) AS lifetime_promoters,
             count(
               CASE
                 WHEN (r.recommend <= 6) THEN r.dealer_partner_id
                 ELSE NULL :: integer
                   END) AS lifetime_detractors,
             count(
               CASE
                 WHEN (r.recommend IS NOT NULL) THEN r.dealer_partner_id
                 ELSE NULL :: integer
                   END) AS lifetime_total_reviews
      FROM (rating r
          JOIN dealer_partners dp ON ((dp.id = r.dealer_partner_id)))
      GROUP BY dp.name
)

,almost as (

SELECT rolling_nps.*, 
       lifetime_promoters, 
       lifetime_detractors,
       lifetime_total_reviews,
       ROUND(((((rolling_nps.rolling_promoters) :: double precision / (NULLIF(rolling_nps.rolling_total_reviews, 0)) :: double precision) -
           ((rolling_nps.rolling_detractors) :: double precision / (NULLIF(rolling_nps.rolling_total_reviews, 0)) :: double precision)) *
          (100) :: double precision)::decimal, 2)                                AS rolling_nps,
        ROUND(((((t.lifetime_promoters) :: double precision / (NULLIF(t.lifetime_total_reviews, 0)) :: double precision) -
           ((t.lifetime_detractors) :: double precision / (NULLIF(t.lifetime_total_reviews, 0)) :: double precision)) *
          (100) :: double precision)::decimal, 2)                                AS lifetime_nps,
        'https://dealers.roadster.com/' || dp.dpid || '/ratings' ratings_urls
FROM rolling_nps
LEFT JOIN (
SELECT *
FROM lifetime) t on rolling_nps.name = t.name
LEFT JOIN dealer_partners dp ON rolling_nps.name = dp.name

 ),
 
filter_for_dpids as (
  -- Generate the Dealer Group associated with the dpid param filter
  -- Sets up the entire query. Needs the dpsk and the dpid from params to work
  SELECT DISTINCT CASE WHEN di.dealer_group IS NULL THEN dealer_name ELSE di.dealer_group END dealer_group
  FROM fact.salesforce_dealer_info di
  INNER JOIN public.dealer_partners dp on di.dpid = dp.dpid
  WHERE set_dealer IS TRUE
)


,dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE CASE WHEN dealer_group IS NULL THEN dealer_name ELSE dealer_group END IN (SELECT * FROM filter_for_dpids)
AND dp.status = 'Live'
--and dealer_group <> dp.name
)

 
SELECT *
FROM almost
WHERE name in (SELECT initcap(name) FROM dpids)

 
 
 