SELECT date, payload->'rooftop' AS rooftop,
             payload->'make' AS make,
             payload->'source' AS source,
             -- total vehicles
             (payload->>'total')::int AS total,
             -- conf >= 90
             (payload->>'nvalid')::int AS nvalid,
             -- conf in (50..90), visible on store
             (payload->>'nminorerrors')::int AS nequiperrors,
             -- no style match
             (payload->>'nstyleerrors')::int AS nstyleerrors
FROM stats
WHERE name = 'used-inventory'