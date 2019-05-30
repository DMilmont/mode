
with date_dpid as (
select distinct c.date, dp.dpid, dp.name, dp.tableau_secret as dpsk, dp.status current_status, dp.success_manager, dp.integration_manager, dp.actual_live_date
from fact.d_cal_date c
cross join (
  select distinct dp.dpid, dp.tableau_secret, dp.name, sf.status, sf.success_manager, sf.integration_manager,sf.actual_live_date 
  from dealer_partners dp
  left join fact.salesforce_dealer_info sf
  on dp.dpid = sf.dpid) dp 
where c.date between current_date-14 and current_date-1
)


,traffic as (
select *
from fact.mode_agg_daily_traffic_and_prospects
where date between current_date-14 and current_date-1
and type in ('Dealer Visitors','Online Express Traffic','Online Express SRP Traffic','Online Express VDP Traffic')
)

,dealer_visitors as (
select 
  dpid
, dpsk
, sum(count) dealer_visitors
from traffic
where type = 'Dealer Visitors'
group by 1,2)

,online_express_traffic as (
select 
  dpid
, dpsk
, sum(count) online_express_visitors
from traffic
where type = 'Online Express Traffic'
group by 1,2)

,online_express_srp_traffic as (
select 
  dpid
, dpsk
, sum(count) as online_express_srp_visitors
from traffic
where type = 'Online Express SRP Traffic'
group by 1,2)


,online_express_vdp_traffic as (
select 
  dpid
, dpsk
, sum(count) as online_express_vdp_visitors
from traffic
where type = 'Online Express VDP Traffic'
group by 1,2)


select 
  dd.success_manager as "Success Owner"
,dd.dpid
, 'MISSING!!' as "GA Tags"
, et.online_express_visitors as "Online ES Visitors"
, to_char(dd.actual_live_date, 'YYYY-MM-DD') as "Go Live Date"
, dd.current_status as "Status"
, dd.name as "Dealer Name"
, dd.integration_manager as "Integration Owner"

from date_dpid dd 
left join online_express_traffic et on et.dpid = dd.dpid 
left join dealer_visitors dt on dt.dpid = dd.dpid 
left join online_express_vdp_traffic vdp on vdp.dpid = dd.dpid
left join online_express_srp_traffic srp on srp.dpid = dd.dpid
where dealer_visitors is null 
and online_express_visitors > 20  -- let's focus on the dealers with real ES traffic.  
and current_status = 'Live'
and dd.dpid not in (
 -- dealers that don't provide traffic 
 'fordfairfield'
,'johnelwaycadillac'
,'markmillersubarumidtown'
,'markmillersubarusouthtowne'
,'serramonteford'
,'johnelwaychevrolet'
,'autoletgo'
,'cabetoyota'
,'drivelineautos'
,'lincolnfairfield'
,'planethondanj'
,'sierratoyota'
,'wellsfargo'
,'buysideauto'
,'audiowingsmills'
,'continentalaudi'
,'edwardsautogroup'
,'lithiamotors'
,'bryanhonda'
,'morristowncadillac'
,'edwardsmitsubishicouncilbluffs'
,'kleinhonda'
,'pinebeltsubaru'
,'bmwoftowson'
,'applevalleylincoln'
,'kainford'
,'lithiatoyotaspringfield'
,'dayapollosubaru'
,'volvomarin'
,'graingerhonda'
,'bermaninfinitichicago'
,'bermannissanchicago'
,'bermansubaruchicago'
,'bermannissanmerrillville'
,'floridafinecars'
, 'floridafinecarshollywood'
, 'floridafinecarsmargate'
, 'floridafinecarsmiami'
, 'floridafinecarswestpalmbeach'
, 'sunautogroup'
, 'sunautowarehousecicero'
, 'sunautowarehousecortland'
, 'sunchevroletchittenango')
group by 1,2,3,4,5,6,7,8
--order by sf.account_success_owner, "Go Live Date" DESC
;