rm -rf /var/lib/mysql-files/result.txt
user="mhoundegnon"
pwd="PasS123"

mysql -u$user -p$pwd -e "
	use temp_db;

	DROP TABLE IF EXISTS temp_db.fmi_list;

	TRUNCATE TABLE temp_db.scans_by_fmi;
	
	CREATE TABLE fmi_list (
  		fmi_id bigint(25) NOT NULL,
  		PRIMARY KEY (fmi_id)
	) ENGINE=InnoDB;

	INSERT IGNORE INTO temp_db.fmi_list 
	SELECT DISTINCT fmi FROM ods.ods_scan_data WHERE fmi not in (-1,-2) AND date_scanned >='2017-01-01';
	"

mysql -u$user -p$pwd -e "
		use temp_db;
		call temp_db.sp_process_history_fmi_list();
		"

 mailx -v -A freeosk -s "CMS Phase 1 Done" -a /root/script/scans_by_fmi_temp.log  mikael.houndegnon@thefreeosk.com <<< "Done"

