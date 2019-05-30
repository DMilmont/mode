SELECT date, payload->'dpid' AS dpid,
             payload->'make' AS make,
             payload->'model' AS model,
             payload->'year' AS year,
             payload->'source' AS source,
             -- total vehicles
             (payload->>'total')::int AS total,
             -- conf >= 90
             (payload->>'nvalid')::int AS nvalid,
             -- conf in (50..90), visible on store
             (payload->>'nminorerrors')::int AS nminorerrors,
             -- conf < 50, not viisible on store
             (payload->>'nmajorerrors')::int AS nmajorerrors,
             -- no style match
             (payload->>'nstyleerrors')::int AS nstyleerrors,
             -- no builddata (no vehicle spec)
             (payload->>'nbuilddataerrors')::int AS nbuilddataerrors,

             ((payload->>'nvalid')::float / (payload->>'total')::float) * 100 as pct_valid,
             ((payload->>'nvalid')::float + (payload->>'nminorerrors')::float) / (payload->>'total')::float * 100 as pct_visible

FROM stats
WHERE name = 'dealer-inventory'