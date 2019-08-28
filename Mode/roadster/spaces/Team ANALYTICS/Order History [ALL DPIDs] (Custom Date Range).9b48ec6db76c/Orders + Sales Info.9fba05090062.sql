
with
order_steps as (
SELECT
        (order_submitted.order_step_dbid) :: text AS order_step_id,
         'Order Submitted' :: text                 AS "Item Type",
         order_submitted."timestamp",
         order_submitted.order_id,
         order_submitted.user_id,
         order_submitted.dealer_partner_id,
         order_submitted.duration,
         order_submitted.is_final
         ,agent_id,
         100                                       AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((order_submitted order_submitted
      JOIN users b ON ((order_submitted.user_id = b.id)))
      JOIN orders c ON ((order_submitted.order_id = c.id)))
  UNION ALL
  SELECT (deal_sheet_sent.order_step_dbid) :: text AS order_step_id,
         'Deal Sheet Sent' :: text                 AS "Item Type",
         deal_sheet_sent."timestamp",
         deal_sheet_sent.order_id,
         deal_sheet_sent.user_id,
         deal_sheet_sent.dealer_partner_id,
         deal_sheet_sent.duration,
         deal_sheet_sent.is_final
         ,agent_id,
         200                                       AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((deal_sheet_sent deal_sheet_sent
      JOIN users b ON ((deal_sheet_sent.user_id = b.id)))
      JOIN orders c ON ((deal_sheet_sent.order_id = c.id)))
  UNION ALL
  SELECT (deal_sheet_accepted.order_step_dbid) :: text AS order_step_id,
         'Deal Sheet Accepted' :: text                 AS "Item Type",
         deal_sheet_accepted."timestamp",
         deal_sheet_accepted.order_id,
         deal_sheet_accepted.user_id,
         deal_sheet_accepted.dealer_partner_id,
         deal_sheet_accepted.duration,
         deal_sheet_accepted.is_final
         ,agent_id,
         300                                           AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((deal_sheet_accepted
      JOIN users b ON ((deal_sheet_accepted.user_id = b.id)))
      JOIN orders c ON ((deal_sheet_accepted.order_id = c.id)))
  UNION ALL
  SELECT (credit_completed.order_step_dbid) :: text AS order_step_id,
         'Credit Completed' :: text                 AS "Item Type",
         credit_completed."timestamp",
         credit_completed.order_id,
         credit_completed.user_id,
         credit_completed.dealer_partner_id,
         credit_completed.duration,
         credit_completed.is_final
         ,agent_id,
         400                                        AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((credit_completed
      JOIN users b ON ((credit_completed.user_id = b.id)))
      JOIN orders c ON ((credit_completed.order_id = c.id)))
  UNION ALL
  SELECT (service_plans_completed.order_step_dbid) :: text AS order_step_id,
         'Service Plans Completed' :: text                 AS "Item Type",
         service_plans_completed."timestamp",
         service_plans_completed.order_id,
         service_plans_completed.user_id,
         service_plans_completed.dealer_partner_id,
         service_plans_completed.duration,
         service_plans_completed.is_final
         ,agent_id,
         500                                               AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((service_plans_completed
      JOIN users b ON ((service_plans_completed.user_id = b.id)))
      JOIN orders c ON ((service_plans_completed.order_id = c.id)))
  UNION ALL
  SELECT (accessories_completed.order_step_dbid) :: text AS order_step_id,
         'Accessories Completed' :: text                 AS "Item Type",
         accessories_completed."timestamp",
         accessories_completed.order_id,
         accessories_completed.user_id,
         accessories_completed.dealer_partner_id,
         accessories_completed.duration,
         accessories_completed.is_final
         ,agent_id,
         501                                             AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((accessories_completed
      JOIN users b ON ((accessories_completed.user_id = b.id)))
      JOIN orders c ON ((accessories_completed.order_id = c.id)))
  UNION ALL
  SELECT (final_deal_sent.order_step_dbid) :: text AS order_step_id,
         'Final Deal Sent' :: text                 AS "Item Type",
         final_deal_sent."timestamp",
         final_deal_sent.order_id,
         final_deal_sent.user_id,
         final_deal_sent.dealer_partner_id,
         final_deal_sent.duration,
         final_deal_sent.is_final
         ,agent_id,
         600                                       AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((final_deal_sent
      JOIN users b ON ((final_deal_sent.user_id = b.id)))
      JOIN orders c ON ((final_deal_sent.order_id = c.id)))
  UNION ALL
  SELECT (final_deal_accepted.order_step_dbid) :: text AS order_step_id,
         'Final Deal Accepted' :: text                 AS "Item Type",
         final_deal_accepted."timestamp",
         final_deal_accepted.order_id,
         final_deal_accepted.user_id,
         final_deal_accepted.dealer_partner_id,
         final_deal_accepted.duration,
         final_deal_accepted.is_final
         ,agent_id,
         700                                           AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((final_deal_accepted
      JOIN users b ON ((final_deal_accepted.user_id = b.id)))
      JOIN orders c ON ((final_deal_accepted.order_id = c.id)))
  UNION ALL
  SELECT ('order-' :: text || order_completed.order_id) AS order_step_id,
         'Order Completed' :: text                      AS "Item Type",
         order_completed."timestamp",
         order_completed.order_id,
         order_completed.user_id,
         order_completed.dealer_partner_id,
         order_completed.duration,
         order_completed.is_final
         ,agent_id,
         800                                            AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((order_completed
      JOIN users b ON ((order_completed.user_id = b.id)))
      JOIN orders c ON ((order_completed.order_id = c.id)))
  UNION ALL
  SELECT ('order-' :: text || order_cancelled.order_id) AS order_step_id,
         'Order Cancelled' :: text                      AS "Item Type",
         order_cancelled."timestamp",
         order_cancelled.order_id,
         order_cancelled.user_id,
         order_cancelled.dealer_partner_id,
         order_cancelled.duration,
         order_cancelled.is_final
         ,agent_id,
         801                                            AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((order_cancelled
      JOIN users b ON ((order_cancelled.user_id = b.id)))
      JOIN orders c ON ((order_cancelled.order_id = c.id)))
)



, order_status as (SELECT
     order_id
     ,dealer_partner_id
     ,max(user_id) "user_id"
     ,max(agent_id) "agent_id"
     ,min(timestamp) as "orderstart"
     ,max(timestamp) as "laststep"
     ,max(case when "Item Type" = 'Order Submitted' then 'os' end) as "os"
     ,max(case when "Item Type" = 'Deal Sheet Sent' then 'ds' end) as "ds"
     ,max(case when "Item Type" = 'Deal Sheet Accepted' then 'da' end) as "da"
     ,max(case when "Item Type" = 'Credit Completed' then 'cc' end) as "cc"
     ,max(case when "Item Type" = 'Service Plans Completed' then 'sp' end) as "sp"
     ,max(case when "Item Type" = 'Accessories Completed' then 'ac' end) as "ac"
     ,max(case when "Item Type" = 'Final Deal Sent' then 'fds' end) as "fds"
     ,max(case when "Item Type" = 'Final Deal Accepted' then 'fda' end) as "fda"
     ,max(case when "Item Type" = 'Order Completed' then 'Complete' end) as "complete"
     ,max(case when "Item Type" = 'Order Cancelled' then 'Cancelled' end) as "cancelled"

     from order_steps

     group by 1,2
     )


, accessories as (SELECT
    order_id, count(1), sum(price) as amt
    FROM public.accessories
    group by 1)

, serviceplans as (SELECT
    order_id, count(1), sum(price) as amt
    FROM public.plans
    group by 1)

, matched_sales as (
  SELECT
  DISTINCT
  dpid,
  initcap(coalesce(agent1, agent2)) agent_name,
  first_name buyer_first_name,
  last_name buyer_last_name,
  initcap(first_name) || ' ' || initcap(last_name) buyer_full_name,
  vin,
  1 exist
  FROM crm_records crm
  LEFT JOIN dealer_partners dp ON crm.dealer_partner_id = dp.id
  WHERE sold_at IS NOT NULL
  and vin is not null
  and coalesce(agent1, agent2) is not null
  and initcap(first_name) || ' ' || initcap(last_name) is not null
)

, base_order_data as (
select
  row_number() OVER (ORDER BY os.orderstart) ind,
  dp.dpid as "DPID"
  ,case when os.cancelled = 'Cancelled' then 'Cancelled' when os.complete = 'Complete' then 'Complete' else 'Open' end as "Status"
  ,o.order_type "Order Type"
  ,o.order_dbid as "Application Order ID"
  ,os.order_id as "order_id"
  ,case when u.in_store = true then 'In Store' else 'Online' end as "Source"
  ,initcap(agent.first_name) || ' ' || initcap(agent.last_name) as "Agent"
  ,os.os
  ,os.ds
  ,os.da
  ,COALESCE(ti.status, case when tc.is_final = true then 'notrade' else '' end) "ts"
  ,os.sp
  ,serviceplans.count as "sp#"
  ,to_char(serviceplans.amt,'L999,999') as "sp$"
  ,os.ac
  ,accessories.count as "a#"
  ,to_char(accessories.amt, 'L999,999') as "a$"
  ,os.cc
  ,os.fds
  ,os.fda
  ,to_char(os.orderstart, 'YYYY_MM_DD Dy HH:MM:SSam') "Order Start"
  ,to_char(os.laststep, 'YYYY_MM_DD Dy HH:MM:SSam') "Last Step"
  ,initcap(u.first_name) || ' ' || initcap(u.last_name) as "Customer"
  ,o.vin
  ,o.grade
  ,o.year
  ,o.model
  ,o.deal_type
  ,to_char(o.price,'L999,999') as "Price"
  ,to_char(o.payment, 'L999,999') as "Payment"
  ,to_char(o.down_payment, 'L999,999') as "Down"
  ,o.term as "Term"
  ,o.interest_rate as "Rate"
  ,o.mileage_limit as "Mile Lmt"
  ,ti.vin "TradeIn VIN"
  ,ti.source "TradeIn Source"
  ,ti.trade_in_dbid "TradeIn ID"
  ,ti.model "TradeIn Model"
  ,ti.year "TradeIn year"
  ,ti.mileage "TradeIn Mileage"
  ,tc.timestamp "TradeComplete Timestamp"
  ,tc.duration "TradeComplete Duration"
from order_status os
left join public.orders o on o.id = os.order_id
left join public.users u on u.id = os.user_id
left join public.agents agent on agent.id = os.agent_id
left join public.dealer_partners dp on dp.id = os.dealer_partner_id
left join accessories on accessories.order_id = os.order_id
left join serviceplans on serviceplans.order_id = os.order_id
left join public.trade_ins ti on ti.order_id = os.order_id
left join public.trade_in_completed tc on tc.order_id = os.order_id
where orderstart >= '{{start_date}}'::date 
and orderstart <= '{{end_date}}'::date 
order by os.orderstart desc
)

--- Final Data Triple Join
, everything_match as (
SELECT
DISTINCT
ind,
exist "Bought This Car"
FROM base_order_data bod
LEFT JOIN matched_sales ms ON
  bod."Customer" = ms.buyer_full_name AND
  bod.vin = ms.ViN AND
  bod."Agent" = ms.agent_name
)

, diff_vin as (
SELECT
DISTINCT
ind,
exist "Bought Different Car"
FROM base_order_data bod
LEFT JOIN matched_sales ms ON
  bod."Customer" = ms.buyer_full_name AND
  bod.vin <> ms.ViN AND
  bod."Agent" = ms.agent_name
)

, diff_agent as (
SELECT
DISTINCT
ind,
exist "Bought This Car - Different Agent"
FROM base_order_data bod
LEFT JOIN matched_sales ms ON
  bod."Customer" = ms.buyer_full_name AND
  bod.vin = ms.ViN AND
  bod."Agent" <> ms.agent_name
)

, sales_match_exists as (
SELECT
DISTINCT
ind,
exist "Sales Match Exists"
FROM base_order_data bod
LEFT JOIN matched_sales ms ON
  bod."DPID" = ms.dpid
)
--
 SELECT
 "Bought This Car",
 "Bought Different Car",
 "Bought This Car - Different Agent",
 "Sales Match Exists",
 bod.*
 FROM base_order_data bod
 LEFT JOIN everything_match em ON bod.ind = em.ind
 LEFT JOIN diff_vin dv ON bod.ind = dv.ind
 LEFT JOIN diff_agent da ON bod.ind = da.ind
 LEFT JOIN sales_match_exists sme ON bod.ind = sme.ind
