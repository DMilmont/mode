
SELECT
t.*
FROM (
    SELECT
    l.timestamp AT TIME ZONE 'UTC' AT TIME ZONE dp.timezone "Date & Time of Submission",
    EXTRACT(month from l.timestamp AT TIME ZONE 'UTC' AT TIME ZONE dp.timezone) "Month",
    EXTRACT(year from l.timestamp AT TIME ZONE 'UTC' AT TIME ZONE dp.timezone) "Year",
    dp.name "Name",
    l.type "Lead Type",
    first_name "First Name",
    last_name "Last Name",
    u.city "City",
    u.state "State",
    u.zip "Zip Code",
    u.phone "Phone Number",
    u.email "Email Address"
    FROM lead_submitted l
    LEFT JOIN dealer_partners dp ON l.dealer_partner_id = dp.id
    LEFT JOIN users u ON l.user_id = u.id
    WHERE l.timestamp >= '2019-05-01'
    and dpid ='{{ dpid }}'
) t
ORDER BY t."Name" desc, "Date & Time of Submission" desc