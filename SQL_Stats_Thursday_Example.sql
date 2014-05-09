/*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/
/*                                                         */
/*    Get a list of weather stations in Washington State   */
/*                                                         */
/*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

select
  weather_station_name,
  weather_station_code,
  last_modified_date,
  country_name,
  postal_code,
  latitude,
  longitude
from dim_physical_locations
where 1=1
  and country_code = 'us'
  and postal_code not in('unknown')
  and region_code = 'wa'
  and weather_station_code not in('unknown')
order by weather_station_code, last_modified_date desc;

/*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/
/*                                                         */
/*    Get a list of weather stations in Washington State   */
/*    Getting only the most recent record for each station */
/*                                                         */
/*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

with stations as (
  select
    weather_station_name,
    weather_station_code,
    last_modified_date,
    country_name,
    postal_code,
    latitude,
    longitude,
    row_number() over(partition by weather_station_code order by last_modified_date desc) as rk
  from dim_physical_locations
  where 1=1
    and country_code = 'us'
    and postal_code not in('unknown')
    and region_code = 'wa'
    and weather_station_code not in('unknown')
  order by weather_station_code, last_modified_date desc)
select s.*
from stations s
where s.rk=1
order by weather_station_code, last_modified_date desc;