
sudo pt-online-schema-change --password PasS123  --user mhoundegnon --execute --alter " CHANGE COLUMN first_scan first_scan DATE NOT NULL DEFAULT '0000-00-00' , CHANGE COLUMN last_scan last_scan DATE NOT NULL DEFAULT '0000-00-00' , CHANGE COLUMN total_days total_days INT(7) NOT NULL DEFAULT 0 , CHANGE COLUMN scan_cycle scan_cycle DECIMAL(10,4) NOT NULL DEFAULT 0 , CHANGE COLUMN home_location_id home_location_id INT(11) NOT NULL DEFAULT 0 , CHANGE COLUMN home_location_name home_location_name VARCHAR(100) NOT NULL , CHANGE COLUMN home_location_open home_location_open CHAR(3) NOT NULL , CHANGE COLUMN first_scan_location_id first_scan_location_id INT(11) NOT NULL DEFAULT 0 , CHANGE COLUMN first_scan_location_name first_scan_location_name VARCHAR(100) NOT NULL , CHANGE COLUMN last_scan_location_id last_scan_location_id INT(11) NOT NULL DEFAULT 0 , CHANGE COLUMN last_scan_location_name last_scan_location_name VARCHAR(100) NOT NULL , CHANGE COLUMN first_opt_in_location_id first_opt_in_location_id INT(11) NOT NULL DEFAULT 0 , CHANGE COLUMN first_opt_in_location_name first_opt_in_location_name VARCHAR(100) NOT NULL , CHANGE COLUMN first_opt_in_date first_opt_in_date DATE NOT NULL DEFAULT '0000-00-00' , CHANGE COLUMN last_opt_in_location_id last_opt_in_location_id INT(11) NOT NULL DEFAULT 0 , CHANGE COLUMN last_opt_in_location_name last_opt_in_location_name VARCHAR(100) NOT NULL , CHANGE COLUMN last_opt_in_date last_opt_in_date DATE NOT NULL DEFAULT '0000-00-00' , CHANGE COLUMN home_opt_in_location_id home_opt_in_location_id INT(11) NOT NULL DEFAULT 0 , CHANGE COLUMN home_opt_in_location_name home_opt_in_location_name VARCHAR(100) NOT NULL , CHANGE COLUMN has_email has_email CHAR(3) NOT NULL , CHANGE COLUMN email_capture_source email_capture_source VARCHAR(10) NOT NULL , CHANGE COLUMN has_mobile has_mobile CHAR(3) NOT NULL , CHANGE COLUMN last_wm_scan_date last_wm_scan_date DATE NOT NULL DEFAULT '0000-00-00' , CHANGE COLUMN last_sc_scan_date last_sc_scan_date DATE NOT NULL DEFAULT '0000-00-00'   "  D='temp_db_sl_staging',t='staging_fmi_activity'     

mailx -v -A freeosk -s "ALter table temp_db_sl_staging.staging_fmi_activity" -a /root/script/nohup.log  mikael.houndegnon@thefreeosk.com <<< "Done"
