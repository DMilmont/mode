  SELECT  '{{ end_date }}' AS date,
         p.dpid,
         p.ct_express_visitors                           AS "Clicks",
         p.ct_leads                                      AS "Leads",
         p.ct_trade_in_completed                         AS "Trade-In Evaluations",
         p.ct_test_drive_start                           AS "Appointments Scheduled",
         p.ct_soft_credit_completed                      AS "Credit PreQs",
         p.ct_payment_calc_complete                      AS "Payment Calc Finishes",
         p.ct_pre_approval_completed                     AS "Hard Credit Finishes"
  FROM report_layer.general_lexus_ftp('{{ start_date }}'::date, '{{ end_date }}'::date) p
      LEFT JOIN dealer_partners dp ON (((p.dpid) :: text = (dp.dpid) :: text))
  WHERE ((dp.status) :: text = 'Live' :: text);
