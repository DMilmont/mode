with base_data as (
SELECT
dealer_partner_id,
REPLACE(REPLACE(REPLACE(properties ->> 'dealership_hours', '[[', ''), '],[', '|'), ']]', '') base_hours
FROM dealer_partner_properties
WHERE date = (SELECT max(date) FROM dealer_partner_properties)

),

other_transforms as (
     SELECT
     dealer_partner_id,
     REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(TRIM(UPPER(REPLACE(base_hours, '.', ''))), ' - ', '-'),
                                    ' A', 'A'),
                            ' P', 'P')
         , '([1-9])A', '\1:00A'),
          '([1-9])P', '\1:00P'), '"', '') base_hours
     FROM base_data
    )

SELECT
name,
base_hours,
       REPLACE(split_part(base_hours, '|', 1), '","', ': ') "Monday",
       REPLACE(split_part(base_hours, '|', 2), '","', ': ') "Tuesday",
       REPLACE(split_part(base_hours, '|', 3), '","', ': ') "Wednesday",
       REPLACE(split_part(base_hours, '|', 4), '","', ': ') "Thursday",
       REPLACE(split_part(base_hours, '|', 5), '","', ': ') "Friday",
       REPLACE(split_part(base_hours, '|', 6), '","', ': ') "Saturday",
       REPLACE(split_part(base_hours, '|', 7), '","', ': ') "Sunday"
FROM other_transforms ot
LEFT JOIN dealer_partners dp ON ot.dealer_partner_id = dp.id
WHERE
name = {{ dealer_name }}