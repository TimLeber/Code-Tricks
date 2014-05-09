select
  web_id,
  cal_date,
  site_name,
  phone_number,
  consumer_id,
  Department,
  type,
  star_rating,
  loyalty_score,
  comments
from (
select
  to_date(fsm.dim_transaction_date_key, 'j') as cal_date,
  f1.web_id,
  f1.site_name,
  0 as phone_number,
  fsm.consumer_id,
  fsm.transaction_id,
  'Sales' as Department,
  ip.certified as type,
  coalesce(fsm.star_rating,0) as star_rating,
  coalesce(fsm.loyalty_score,0) as loyalty_score,
  '' as comments
from fact_sales_milestones as fsm 
  join (
    select
      si.dim_securable_item_key,
      si.web_id,
      si.site_name
    from dim_securable_items as si
      join dim_corp_hiers as ch using(dim_securable_item_key)
    where 1=1
      and ch.hier_display_name ='Hendrick') as f1 
  on fsm.dim_site_key = f1.dim_securable_item_key
  join dim_inventory_physical as ip using(dim_inventory_physical_key)
where 1=1
  and fsm.dim_transaction_date_key >= to_char(to_date('01/01/2014','mm/dd/yyyy'),'J')::integer
  
union all

select
  to_date(fsv.dim_transaction_date_key, 'j') as cal_date,
  f2.web_id,
  f2.site_name,
  0 as phone_number,
  fsv.consumer_id,
  fsv.transaction_id,
  'Service' as Department,
  ip.certified as type,
  coalesce(fsv.star_rating,0) as star_rating,
  coalesce(fsv.loyalty_score,0) as loyalty_score,
  '' as comments
from fact_service_milestones as fsv 
  join (
    select
      si.dim_securable_item_key,
      si.web_id,
      si.site_name
    from dim_securable_items as si
      join dim_corp_hiers as ch using(dim_securable_item_key)
    where 1=1
      and ch.hier_display_name ='Hendrick') as f2 
  on fsv.dim_site_key = f2.dim_securable_item_key
  join dim_inventory_physical as ip using(dim_inventory_physical_key)
where 1=1
  and fsv.dim_transaction_date_key >= to_char(to_date('01/01/2014','mm/dd/yyyy'),'J')::integer) as blah
order by
  web_id, cal_date, consumer_id;