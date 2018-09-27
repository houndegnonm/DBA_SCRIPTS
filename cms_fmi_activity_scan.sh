user="mhoundegnon"
pwd="PasS123"

sudo rm -rf /var/lib/mysql-files/fmi_list.txt

mysql -u$user -p$pwd -e "
	use temp_db_sl_staging;

	DROP TABLE IF EXISTS temp_db_sl_staging.fmi_list;

	TRUNCATE TABLE temp_db_sl_staging.scans_by_fmi;
	
	CREATE TABLE temp_db_sl_staging.fmi_list (
  		fmi_id bigint(25) NOT NULL,
  		PRIMARY KEY (fmi_id)
	) ENGINE=InnoDB;

	SELECT DISTINCT fmi
	INTO OUTFILE '/var/lib/mysql-files/fmi_list.txt'
        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'
        LINES TERMINATED BY '\n'
        FROM ods.ods_scan_data
        WHERE fmi Not IN (-1,-2)
	AND date_scanned >='2017-01-01';

        LOAD DATA INFILE '/var/lib/mysql-files/fmi_list.txt'
        INTO TABLE temp_db_sl_staging.fmi_list
        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';
	"

mysql -u$user -p$pwd -e "
		use temp_db;
		call temp_db.sp_process_history_scan_fmi_list();
		"

 mailx -v -A freeosk -s "CMS Phase 1 Done" -a /root/script/scans_by_fmi_temp.log  mikael.houndegnon@thefreeosk.com <<< "Done"

