SELECT tsd.* 
      ,COALESCE(sf.dealer_website_url, 'Website Not Available in Salesforce')as "Dealer Site"
FROM
  (
  SELECT DISTINCT "Success Manager" as "DSM"
                  ,wts.DPID as "DPID"
                  ,date("Date of Sudden Drop") as "Date of Sudden Drop"
                  ,"Days Since First Drop"
                  ,'GA Tags Removed' as "Potential Issue"
  FROM report_layer.vw_mode_web_traffic_sudden_drop wts
  UNION
  SELECT DISTINCT "Success Manager" as "DSM"
                  ,wts.DPID as "DPID"
                    ,date("Date of Sudden Drop") as "Date of Sudden Drop"
                  ,"Days Since First Drop"
                  ,'Express CTAs Broken' as "Problem"
  FROM report_layer.vw_mode_exp_traffic_sudden_drop wts
  ) tsd
  LEFT JOIN fact.salesforce_dealer_info sf ON tsd."DPID"=sf.dpid   
  ORDER BY "Days Since First Drop" desc,"DSM"