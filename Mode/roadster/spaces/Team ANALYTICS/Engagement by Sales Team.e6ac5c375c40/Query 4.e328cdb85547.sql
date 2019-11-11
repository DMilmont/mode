with agents as (
    select pa.*
    , case when training_type is NULL then false else true end as "certified" 
    from public.agents pa 
    left join public.agent_certifications_data ac on ac.email = pa.email
    where pa.email in ('dmaltin@mblaguna.com'  )
)
,ga as (select 
    gas.dpid
    , ag.first_name || ' ' || ag.last_name agent 
    , ag.email
    , ag.job_title 
    , ag.department
    , gap.timestamp at time zone 'UTC' at time zone dp.timezone "Dealer Time"
    , round(gas.duration::decimal/60,1) "Session Minutes"
    , round(gap.time_on_page::decimal/60,1) "Minutes on Page"
    , gap.property
    , gas.in_store
    , gap.page_path
    , gap.previous_page_path
    , embedded
    , gap.url
    , gas.device_category
    , gas.operating_system
    , gas.distinct_id "session_distinct_id"
    , gap.distinct_id "page_distinct_id"
    , gas.agent_dbid
    , ag.certified
    , gas.session_count
    , ag.last_login_at at time zone 'UTC' at time zone dp.timezone "Last Login"
    , gap.id "Page ID"
    , gas.id "Session ID"

    from public.ga2_sessions gas
    left join public.ga2_pageviews gap on gap.ga2_session_id = gas.id
    inner join agents ag on ag.distinct_id = gas.agent_dbid
    left join public.dealer_partners dp on dp.dpid = gas.dpid 
where gas.agent_dbid is not null 
and gas.timestamp > '06/01/2019'::date
--gas.in_store = true 
and url is not null 
and gap.timestamp is not null 
and gas.dpid <> 'roadster'
order by gap.id desc 
limit 1048574) --Excel's row limit

,tab1 as (
select 
case when page_path in('/modal/accessories-modal','/virtual/purchase-accessories') then 'Accessories'
     when page_path in('/modal/standard-equipment-modal','/Build Your Own','/modeloverview','/modal/modal-style-compare','/studio','/virtual/modal-style-compare') then 'Build Your Own'
     when page_path in('/financing','/Credit Application','/modal/credit-app','/virtual/purchase-credit','/modal/modal-credit-app-pre-approval-inquiry','/modal/modal-add-coapplicant','/Credit App Authentication Modal','/modal/credit-app-phone-modal','/modal/credit-app-authentication-modal','/modal/credit-score-selection-modal','/modal/soft-credit-modal') then 'Credit/Finance'
     when page_path in('/modal/modal-customer-check-in','/Customer Information','/modal/modal-new-customer','/Customer Lookup') then 'Customer Check Ins'
     when page_path in('/modal/modal-adjust-price','/modal/zip-code-modal','/modal/price-unlock-modal','/New VDP','/Used VDP','/modal/modal-vehicle-slideshow','/modal/used-details-modal','/modal/walk-around-modal','/modal/modal-payment-comparison','/modal/modal-price-summary','/modal/used-details-modal') then 'VDP'
     when page_path in('/Trade-In Wizard','/sell_your_car','/modal/trade-pending','/modal/express-trade-image-tip-modal','/modal/modal-custom-trade-valuation','/virtual/purchase-trade-in','/modal/express-trade-vin-tip-modal','/modal/modal-kbb-ico','/Standalone Trade','/modal/modal-whatis-vin') then 'Trade'
     when page_path in('/New Inventory','/Used Inventory','/modal/vehicle-finder-modal','/virtual/new-inventory','/virtual/used-inventory','/Vehicle Recommender','/new/') then 'SRP'
     when page_path in('/modal/service-plans-modal','/virtual/purchase-service-plans') then 'Service Plans'
     when page_path in('/instore_purchase','/virtual/order-location','/virtual/initial-deal-sheet','/modal/purchase-step-confirmation-modal','/virtual/order-steps','/virtual/order-contact','/virtual/final-deal-sheet','/modal/modal-accept-terms','/virtual/order-password','/modal/in-store-purchase-modal','/modal/duplicate-order-modal','/Delivery Checklist','/instore_purchase_credit','/virtual/purchase-schedule') then 'Order Steps'
     when page_path in('/vehicle_reservation','/modal/modal-already-reserved-contact','/modal/modal-vehicle-reservation') then 'Reservation'
     when page_path in('/modal/modal-test-drive') then 'Test Drive'
     when page_path in('/Homepage','/Welcome', '/Welcome Form') then 'Home and Welcome pages'
     when page_path in('/How It Works') then 'How it Works'
     when page_path in('/modal/share-detail-modal') then 'Share Details'
     when page_path in('/modal/instore-verify-modal', '/modal/sign-in-modal', '/Sign Up', '/Sign In', '/Sign in') then 'Login'
     when page_path in('/Price Unlock Modal') then 'Price Unlock'
     when page_path in('/modal/modal-why-express') then 'Why Express'
     when page_path in('/modal/missing-vin-modal','/modal/out-of-stock-vin-modal') then 'Why Express'
     when page_path in('/modal/save-deal-modal') then 'Save Deal'
     
     when property = 'Main Sites' and page_path = '/' then 'Mainsite Homepage'
     
     when property = 'Main Sites' and page_path ilike '%?vin=%' then 'Mainsite VDP'
     when property = 'Main Sites' and page_path ilike '/new/%' and page_path ilike '%.htm' then 'Mainsite VDP'
     when property = 'Main Sites' and page_path ilike '/used/%' and page_path ilike '%.htm' then 'Mainsite VDP'
     when property = 'Main Sites' and page_path ilike '/certified/%' and page_path ilike '%.htm' then 'Mainsite VDP'
     when property = 'Main Sites' and page_path ilike '/bargain/%' and page_path ilike '%.htm' then 'Mainsite VDP'
     when property = 'Main Sites' and page_path ilike '/commercial-new/%' and page_path ilike '%.htm' then 'Mainsite VDP'
     when property = 'Main Sites' and page_path ilike '/commercial-used/%' and page_path ilike '%.htm' then 'Mainsite VDP'
     when property = 'Main Sites' and page_path ilike '/exotic-new/%' and page_path ilike '%.htm' then 'Mainsite VDP'
     when property = 'Main Sites' and page_path ilike '/exotic-used/%' and page_path ilike '%.htm' then 'Mainsite VDP'
     when property = 'Main Sites' and page_path ilike '/wholesale-new/%' and page_path ilike '%.htm' then 'Mainsite VDP'
     when property = 'Main Sites' and page_path ilike '/wholesale-used/%' and page_path ilike '%.htm' then 'Mainsite VDP'
     when property = 'Main Sites' and page_path ~ '\/\d{8}\/$' then 'Mainsite VDP'
     when property = 'Main Sites' and page_path ilike '%/Inquiry/Details.aspx' then 'Mainsite VPD'
     
     when property = 'Main Sites' and page_path ilike '%inventory%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%used%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%new%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '/certified%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '/bargain%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '/showroom%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%vehicle%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%search%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '/sale%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '/pre-owned%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%models%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%under-%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%/2018%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%/2019%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%/2020%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%/2021%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%/2022%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%demos%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%/cars/%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%/coupe/%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%/suvs/%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%/trucks/%' then 'Mainsite SRP'
     
     when property = 'Main Sites' and page_path ilike '%financ%' then 'Mainsite Credit/Finance'
     when property = 'Main Sites' and page_path ilike '%credit%' then 'Mainsite Credit/Finance'
     when property = 'Main Sites' and page_path ilike '%loans%' then 'Mainsite Credit/Finance'
     when property = 'Main Sites' and page_path ilike '%approv%' then 'Mainsite Credit/Finance'
     when property = 'Main Sites' and page_path ilike '%ualified%' then 'Mainsite Credit/Finance'
     when property = 'Main Sites' and page_path ilike '%insurance%' then 'Mainsite Credit/Finance'
     when property = 'Main Sites' and page_path ilike '%arranties%' then 'Mainsite Credit/Finance'

     when property = 'Main Sites' and page_path ilike '%rent%' then 'Mainsite Car Rental'
     
     when property = 'Main Sites' and page_path ilike '%thank%' then 'Mainsite Thank You Page'

     when property = 'Main Sites' and page_path ilike '%trade%' then 'Mainsite Trade'
     when property = 'Main Sites' and page_path ilike '%kbb%' then 'Mainsite Trade'
     when property = 'Main Sites' and page_path ilike '%sell-your%' then 'Mainsite Trade'
     
     
     when property = 'Main Sites' and page_path ilike '%warranty%' then 'Mainsite Protection Plans'
     when property = 'Main Sites' and page_path ilike '%ccessor%' then 'Mainsite Accessories'
     
     when property = 'Main Sites' and page_path ilike '%requently%' then 'Mainsite FAQ'
     when property = 'Main Sites' and page_path ilike '%FAQ%' then 'Mainsite FAQ'

     when property = 'Main Sites' and page_path ilike '%about%' then 'Mainsite About'
     when property = 'Main Sites' and page_path ilike '%contact%' then 'Mainsite About'
     when property = 'Main Sites' and page_path ilike '%staff%' then 'Mainsite About'
     when property = 'Main Sites' and page_path ilike '%about' then 'Mainsite About'
     
     when property = 'Main Sites' and page_path ilike '%incentives%' then 'Mainsite Incentives'
     when property = 'Main Sites' and page_path ilike '%rebate%' then 'Mainsite Incentives'
     when property = 'Main Sites' and page_path ilike '%military%' then 'Mainsite Incentives'
     when property = 'Main Sites' and page_path ilike '%sell-my%' then 'Mainsite Incentives'
     
     when property = 'Main Sites' and page_path ilike '%calculator%' then 'Mainsite Payment Calculator'
     
     when property = 'Main Sites' and page_path ilike '%service%' then 'Mainsite Service'
     when property = 'Main Sites' and page_path ilike '%parts%' then 'Mainsite Service'
     when property = 'Main Sites' and page_path ilike '%collision%' then 'Mainsite Service'
     when property = 'Main Sites' and page_path ilike '%maintenance%' then 'Mainsite Service'
     
     when property = 'Main Sites' and page_path ilike '%test-drive%' then 'Mainsite Test Drive'
     
     when property = 'Main Sites' and page_path ilike '%promotion%' then 'Mainsite Promotions'
     when property = 'Main Sites' and page_path ilike '%offer%' then 'Mainsite Promotions'
     when property = 'Main Sites' and page_path ilike '%special%' then 'Mainsite Promotions'
     when property = 'Main Sites' and page_path ilike '%ads%' then 'Mainsite Promotions'
     when property = 'Main Sites' and page_path ilike '%zero-down%' then 'Mainsite Promotions'
     when property = 'Main Sites' and page_path ilike '%0-down%' then 'Mainsite Promotions'
     when property = 'Main Sites' and page_path ilike '%deals%' then 'Mainsite Promotions'
     when property = 'Main Sites' and page_path ilike '%program%' then 'Mainsite Promotions'
     when property = 'Main Sites' and page_path ilike '%sale%' then 'Mainsite Promotions'
     when property = 'Main Sites' and page_path ilike '%Sale%' then 'Mainsite Promotions'
     
     when property = 'Main Sites' and page_path ilike '%hour%' then 'Mainsite hours/directions/locations'
     when property = 'Main Sites' and page_path ilike '%direction%' then 'Mainsite hours/directions/locations'
     when property = 'Main Sites' and page_path ilike '%location%' then 'Mainsite hours/directions/locations'
     when property = 'Main Sites' and page_path ilike '%location' then 'Mainsite hours/directions/locations'
     when property = 'Main Sites' and page_path ilike '%locations' then 'Mainsite hours/directions/locations'
     
     when property = 'Main Sites' and page_path ilike '%/model%' then 'Mainsite Model Page'
     when property = 'Main Sites' and page_path ilike '%-showroom%' then 'Mainsite Model Page'
     
     when property = 'Main Sites' and page_path ilike '%reviews%' then 'Mainsite Why were great'
     when property = 'Main Sites' and page_path ilike '%why-%' then 'Mainsite Why were great'
     when property = 'Main Sites' and page_path ilike '%Why-%' then 'Mainsite Why were great'
          when property = 'Main Sites' and page_path ilike '%romise%' then 'Mainsite Why were great'  --one price promise
     
     when property = 'Main Sites' and page_path ilike '%xpress%' then 'Mainsite Custom Express Pages'
     
     when property = 'Main Sites' and page_path ilike '%sitemap%' then 'Mainsite Sitemap'
     
     
     when property = 'Main Sites' and page_path ilike '%-dealership%' then 'Mainsite Homepage'

     when property = 'Main Sites' and page_path ilike '/?%' then 'Mainsite Homepage'
     when property = 'Main Sites' and page_path ilike '%/home' then 'Mainsite Homepage'
     when property = 'Main Sites' and page_path ilike '%/home/?%' then 'Mainsite Homepage'
     
     when property = 'Main Sites' and page_path ilike '/honda%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '/hyundai%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '/mazda%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '/mercedes%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%acura%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '%honda%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '/subaru%' then 'Mainsite SRP'
     when property = 'Main Sites' and page_path ilike '/toyota%' then 'Mainsite SRP'
     
     end as "PAGE" 
     ,*
     from GA 
     )
     
SELECT
"PAGE",
COUNT(*) ct
FROM tab1
GROUP BY 1

