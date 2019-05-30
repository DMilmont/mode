     SELECT DISTINCT dp.dpid as "DPID"
      FROM dealer_partners dp
        LEFT JOIN fact.salesforce_dealer_info tabAE ON dp.dpid = tabAE.dpid
      WHERE dp.status = 'Live'
      and tabAE.status='Live'
     and off_weeks_since_launch > 6
    ORDER BY dp.dpid

{% form %}

DPID:
    type: select
    default: 'actontoyota'
    label: DPID
    options:
        labels: DPID
        values: DPID

{% endform %}
