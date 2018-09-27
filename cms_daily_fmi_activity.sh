user="mhoundegnon"
pwd="PasS123"
slave="192.168.157.107"
master="192.168.157.106"
v_date=$(date +'%Y-%m-%d')
v_time=$(date +'%H:%M:%S')

sudo rm -rf /var/lib/mysql-files/fmi_scan_list.txt
sudo rm -rf /var/lib/mysql-files/fmi_opt_in_list.txt
sudo rm -rf /var/lib/mysql-files/fmi_activity_staging.txt

mysql -u$user -p$pwd -h$slave -e "
	use temp_db_sl_staging;

	TRUNCATE TABLE temp_db_sl_staging.fmi_list;
	
	SELECT DISTINCT fmi,'SC'
	INTO OUTFILE '/var/lib/mysql-files/fmi_scan_list.txt'
        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'
        LINES TERMINATED BY '\n'
        FROM ods.ods_scan_data
        WHERE fmi Not IN (-1,-2)
	AND date_scanned between date_sub(curdate(), INTERVAL $1 day) AND curdate() ;
	
	LOAD DATA INFILE '/var/lib/mysql-files/fmi_scan_list.txt'
       	INTO TABLE temp_db_sl_staging.fmi_list
       	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';
"

mysql -u$user -p$pwd -h$slave -e "
        use temp_db_sl_staging;

        SELECT DISTINCT ods_opt_in_data.fmi,'OP'
        INTO OUTFILE '/var/lib/mysql-files/fmi_opt_in_list.txt'
        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'
        LINES TERMINATED BY '\n'
        FROM ods.ods_opt_in_data
        WHERE ods_opt_in_data.fmi not in (-1,-2)
	AND date_submitted between date_sub(curdate(), INTERVAL $1 day) AND curdate()
        AND ods_opt_in_data.fmi not in (select fmi FROM temp_db.fmi_activity WHERE total_scans=0 ) ;

        LOAD DATA INFILE '/var/lib/mysql-files/fmi_opt_in_list.txt'
	IGNORE
        INTO TABLE temp_db_sl_staging.fmi_list
        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';
        "

mysql -u$user -p$pwd -h$slave -e "
		use temp_db;
		call temp_db.sp_process_daily_fmi_activity('$v_date', '$v_time');
		"

mysql -u$user -p$pwd -h$slave -e "
       	SELECT *
        INTO OUTFILE '/var/lib/mysql-files/fmi_activity_staging.txt'
        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'
        LINES TERMINATED BY '\n'
        FROM temp_db_sl_staging.staging_fmi_activity
	WHERE (
		db_created_at    = '$v_date'
		OR db_updated_at = '$v_date'
	)
	AND (
		db_created_time    = '$v_time'
                OR db_updated_time = '$v_time'
	)
	 "


ssh root@$master "rm -rf /var/lib/mysql-files/fmi_activity_staging.txt; scp root@$slave:/var/lib/mysql-files/fmi_activity_staging.txt /var/lib/mysql-files/fmi_activity_staging.txt"

mysql -u$user -p$pwd -h$master -e "

        CREATE TEMPORARY TABLE temp_db.fmi_activity_ SELECT * FROM temp_db.fmi_activity  WHERE 1=0;

        LOAD DATA INFILE '/var/lib/mysql-files/fmi_activity_staging.txt'
        INTO TABLE temp_db.fmi_activity_
        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';

        INSERT INTO temp_db.fmi_activity
        SELECT *
        FROM temp_db.fmi_activity_ temp
        ON DUPLICATE KEY UPDATE
        fmi_activity.first_scan                                 = temp.first_scan,
        fmi_activity.last_scan                                  = temp.last_scan,
        fmi_activity.total_scans                                = temp.total_scans,
        fmi_activity.total_days                                 = temp.total_days,
        fmi_activity.scan_cycle                                 = temp.scan_cycle,
        fmi_activity.no_of_programs                             = temp.no_of_programs,
        fmi_activity.no_of_kiosks                               = temp.no_of_kiosks,
        fmi_activity.home_location_id                           = temp.home_location_id,
        fmi_activity.home_location_name                         = temp.home_location_name,
        fmi_activity.home_location_open                         = temp.home_location_open,
        fmi_activity.first_scan_location_id                     = temp.first_scan_location_id,
        fmi_activity.first_scan_location_name                   = temp.first_scan_location_name,
        fmi_activity.last_scan_location_id                      = temp.last_scan_location_id,
        fmi_activity.last_scan_location_name                    = temp.last_scan_location_name,
        fmi_activity.first_opt_in_location_id                   = temp.first_opt_in_location_id,
        fmi_activity.first_opt_in_location_name                 = temp.first_opt_in_location_name,
        fmi_activity.first_opt_in_date                          = temp.first_opt_in_date,
        fmi_activity.last_opt_in_location_id                    = temp.last_opt_in_location_id,
        fmi_activity.last_opt_in_location_name                  = temp.last_opt_in_location_name,
        fmi_activity.last_opt_in_date                           = temp.last_opt_in_date,
        fmi_activity.home_opt_in_location_id                    = temp.home_opt_in_location_id,
        fmi_activity.home_opt_in_location_name                  = temp.home_opt_in_location_name,
        fmi_activity.has_email                                  = temp.has_email,
        fmi_activity.email_capture_source                       = temp.email_capture_source,
        fmi_activity.has_mobile                                 = temp.has_mobile,
        fmi_activity.last_wm_scan_date                          = temp.last_wm_scan_date,
       	fmi_activity.last_sc_scan_date                          = temp.last_sc_scan_date,
        fmi_activity.db_updated_at                              = temp.db_updated_at,
        fmi_activity.db_updated_time                            = temp.db_updated_time;

        DROP TABLE temp_db.fmi_activity_;
"

mailx -v -A freeosk -s "CMS Phase 1 FMI Activity Done" mikael.houndegnon@thefreeosk.com <<< "Check table fmi_activity for more details"
 
