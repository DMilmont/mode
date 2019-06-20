
  SELECT DISTINCT primary_make "Primary Make"
  FROM public.dealer_partners dp 
  WHERE primary_make IN ({{ primary_make }})

