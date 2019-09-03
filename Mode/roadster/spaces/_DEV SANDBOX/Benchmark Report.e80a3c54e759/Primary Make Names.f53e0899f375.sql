PREPARE query9 as (

  SELECT DISTINCT primary_make "Primary Make"
  FROM public.dealer_partners dp 
  WHERE primary_make IN ($1)
);

execute query9 ({{ primary_make }});
