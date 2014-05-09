# Global Options
setwd("/Users/lebert/Documents/R/");

# Connection to the GreenPlum DB FM01
library(RPostgreSQL);
library(sqldf);
gp_drv <- dbDriver("PostgreSQL", fetch.default.rec = 1000000);

options(sqldf.driver = "SQLite") # setting sqldf to use a diffrent SQL verson other than PostgreSQL

source("Params.R");
# FM01;
fm01 <- dbConnect(gp_drv, host = "greenplum.tuk.cobaltgroup.com", port = 5432, user = UID, password = PWD, dbname = "fm01");

# create some perameters for sql later
idx = -2
s_k = 167635

#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#
#                                                       #
#   The following code will loop through the sql a      #
#   number of times and appends the results to a data   #
#   frame for use later.                                #
#                                                       #
#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#

loop_data <- NULL
  for (i in -1:-24 ){
  print(i)
  vin_views1 <- paste0("
  SELECT
    dd.year_month_start_dt,
    si.web_id,
    si.dim_securable_item_key,
    m.model_display_name,
    coalesce(SUM(CASE WHEN dip.certified IN ('used', 'certified') THEN fv.total_clicks ELSE NULL END),0) as used_vehicle_details
  FROM wca_app.fact_vehicle_events fv
    join wca_app.dim_inventory_physical dip on fv.dim_inventory_physical_key = dip.dim_inventory_physical_key
    join wca_app.dim_dates dd on fv.dim_date_key = dd.dim_date_key
    join wca_app.dim_models m using(dim_model_key)
    join wca_app.dim_securable_items as si on si.dim_securable_item_key = fv.dim_site_key
    join wca_app.dim_corp_hiers as ch using(dim_securable_item_key)
  WHERE 1 = 1
    and ch.hier = 'BMW CPO HIERARCHY'
    and dd.month_offset = ('",i,"')
    and dip.certified IN ('used', 'certified')
  GROUP BY 
    dd.year_month_start_dt, si.web_id, si.dim_securable_item_key, m.model_display_name
  order by
    dd.year_month_start_dt, si.web_id, used_vehicle_details DESC
  limit 10;", collapse = " ")
  vin_views1 <- dbGetQuery(fm01, vin_views1);
  if (nrow(vin_views1)>0) loop_data <- rbind(loop_data, vin_views1)
  };

write.table(vin_views2, file = "Output/Bug177800_Top_Models.csv", append = FALSE, sep = ",", quote=FALSE, col.names = TRUE, row.names = FALSE);

#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#
#                                                       #
#   This code will allow one to feed a specific         #
#   site_key to get data.  Also allows the month offset #
#   to be set as well.                                  #
#                                                       #
#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#

web_sessions <- paste0("
  select
    to_char(dd.year_month_start_dt, 'YYYY-MM-DD') as cal_date,
    ws.dim_site_key,
    ws.dim_year_month_key,
    ws.total_visitors as Total_Visitors,
    ws.total_inventory_searches as Total_Searches,
    ws.total_email_leads as Total_Leads,
    (ws.total_duration / ws.total_visitors) as Average_Time_On_Site
  from web_sessions_ma1 as ws
    join dim_dates dd on dd.dim_date_key = ws.dim_year_month_key
  where ws.dim_site_key = ('",s_k,"')
    and dd.month_offset >= ('",idx,"')", collapse = "");

web_sessions <- dbGetQuery(fm01, web_sessions);

write.table(web_sessions, file = "Output/Bug177800_Traffic_Data.csv", append = FALSE, sep = ",", quote=FALSE, col.names = TRUE, row.names = FALSE);

#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#
#                                                       #
#                  Clean-up your mess!                  #
#                                                       #
#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#

rm(list=ls()); # remove ALL objects