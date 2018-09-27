user="mhoundegnon"
pwd="PasS123"

sudo rm -rf /var/lib/mysql-files/fmi_list.txt
mysql -u$user -p$pwd -e "
	use temp_db_sl_staging;

	TRUNCATE TABLE temp_db_sl_staging.fmi_list;
	
	SELECT DISTINCT fmi
	INTO OUTFILE '/var/lib/mysql-files/fmi_list.txt'
        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'
        LINES TERMINATED BY '\n'
        FROM ods.ods_scan_data
        WHERE fmi Not IN (-1,-2)
	AND date_scanned between date_sub(curdate(), INTERVAL $1 day) AND curdate() ;

       LOAD DATA INFILE '/var/lib/mysql-files/fmi_list.txt'
       INTO TABLE temp_db_sl_staging.fmi_list
       FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';
"

mysql -u$user -p$pwd -e "
		use temp_db;
		call temp_db.sp_process_history_scan_fmi_list();
		"

sudo rm -rf /var/lib/mysql-files/fmi_list.txt
mysql -u$user -p$pwd -e "
	use temp_db_sl_staging;

	TRUNCATE TABLE temp_db_sl_staging.fmi_list;	

        SELECT DISTINCT ods_opt_in_data.fmi
        INTO OUTFILE '/var/lib/mysql-files/fmi_list.txt'
        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'
        LINES TERMINATED BY '\n'
        FROM ods.ods_opt_in_data
        WHERE ods_opt_in_data.fmi not in (-1,-2)
        AND date_submitted  between date_sub(curdate(), INTERVAL $1 day) AND curdate()
        AND ods_opt_in_data.fmi not in (select fmi_activity.fmi FROM temp_db_sl_staging.fmi_activity where first_scan IS NOT NULL) ;

        LOAD DATA INFILE '/var/lib/mysql-files/fmi_list.txt'
        INTO TABLE temp_db_sl_staging.fmi_list
        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';
        "

mysql -u$user -p$pwd -e "
                use temp_db;
                call temp_db.sp_process_history_opt_in_fmi_list();
                "



mailx -v -A freeosk -s "CMS Phase 1 FMI Activity Done" mikael.houndegnon@thefreeosk.com <<< "Check table fmi_activity for more details"
 
