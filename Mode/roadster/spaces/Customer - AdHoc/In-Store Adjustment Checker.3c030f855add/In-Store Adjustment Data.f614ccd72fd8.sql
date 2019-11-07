
WITH base_data as (
SELECT
dpid,
       "Vin",
       timestamp,
       name "Event",
       "Previous Event",
       first_name || ' ' || last_name "Agent",
       email,
       payload ->> 'rebate' "Rebate",
      payload ->> 'express_price' "Express Price",
      payload ->> 'discount_label' "Discount Label",
      payload ->> 'discount' "Discount Price",
      payload ->> 'addition' "Valued Added"

FROM
(
SELECT dpid, in_store, ue.name, agent_id, a.user_dbid,
       a.first_name, a.last_name, a.email, payload, timestamp
FROM user_events ue
LEFT JOIN dealer_partners dp ON ue.dealer_partner_id = dp.id
LEFT JOIN agents a ON ue.agent_id = a.id
WHERE timestamp > (NOW() - '30 day'::interval)
AND a.email NOT ILIKE '%roadster.com'
AND ue.name = 'In-Store Adjustment'
AND dp.dpid = '{{ dpid }}'
) in_store_adjust
LEFT JOIN LATERAL
    (
    SELECT ue.name "Previous Event", payload ->> 'vin' "Vin"
    FROM user_events ue
    LEFT JOIN dealer_partners dp ON ue.dealer_partner_id = dp.id
    LEFT JOIN agents a ON ue.agent_id = a.id
    WHERE timestamp > (NOW() - '30 day':: interval)
    AND dp.dpid ILIKE 'continentalmazda'
    AND a.email NOT ILIKE '%roadster.com'
    AND ue.name <> 'In-Store Adjustment'
    AND timestamp < in_store_adjust.timestamp
    AND agent_id = in_store_adjust.agent_id
    AND payload ->> 'vin' IS NOT NULL
    ORDER BY timestamp DESC
    LIMIT 1
    ) next_up ON TRUE
ORDER BY agent_id, timestamp
    )

SELECT year, make, model, RANK() OVER (ORDER BY "Agent", "Vin") "Unique Vehicle", base_data.*
FROM base_data
LEFT JOIN vehicles v ON base_data."Vin" = v.vin
ORDER BY "Agent", timestamp




