rm -rf /var/lib/mysql-files/result.txt
user="mhoundegnon"
pwd="PasS123"

mysql -u$user -p$pwd -e "
	use ods;
	
	SELECT 
	fmi,
	date(min(scan_time)) first_scan,
	date(max(scan_time)) last_scan,
	count(fmi) total_scans,
	datediff(max(scan_time),min(scan_time)) +1 total_days,
	(datediff(max(scan_time),min(scan_time)) +1)/ count(fmi) scan_cycle,
	count(distinct program_scan_code) no_of_programs,
	count(distinct kiosk_id) no_of_kiosks,
	ods.fmi_home_location_id(fmi) home_location_id,
	ods.fmi_first_scan_location_id(fmi) first_scan_location_id,
	ods.fmi_last_scan_location_id(fmi) last_scan_location_id,
	ods.fmi_first_opt_in_location_id(fmi) first_opt_in_location_id,
	ods.fmi_first_opt_in_date(fmi) first_opt_in_date,
	ods.fmi_last_opt_in_location_id(fmi) last_opt_in_location_id,
	ods.fmi_last_opt_in_date(fmi) last_opt_in_date,
	ods.fmi_last_wm_scan_date(fmi) last_wm_scan_date,
	ods.fmi_last_sc_scan_date(fmi) last_sc_scan_date
	INTO OUTFILE '/var/lib/mysql-files/result.txt'
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'
	LINES TERMINATED BY '\n'
	FROM ods.ods_scan_data 
	WHERE fmi Not IN (-1,-2)
	group by ods_scan_data.fmi;
	
	CREATE TEMPORARY TABLE dwa.scans_by_fmi_temp_ SELECT * FROM dwa.scans_by_fmi_temp WHERE 1=0;

	LOAD DATA INFILE '/var/lib/mysql-files/result.txt'
        INTO TABLE dwa.scans_by_fmi_temp_
        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';
		
	INSERT INTO dwa.scans_by_fmi_temp s
        SELECT * FROM dwa.scans_by_fmi_temp_ temp
        ON DUPLICATE KEY UPDATE
        s.first_scan           	   = temp.first_scan,
        s.last_scan                = temp.last_scan,
        s.total_scans              = temp.total_scans,
        s.total_days               = temp.total_days,
        s.scan_cycle               = temp.scan_cycle,
        s.no_of_programs           = temp.no_of_programs,
        s.no_of_kiosks             = temp.no_of_kiosks,
        s.home_location_id         = temp.home_location_id,
	s.first_scan_location_id   = temp.first_scan_location_id,
	s.last_scan_location_id    = temp.last_scan_location_id,
	s.first_opt_in_location_id = temp.first_opt_in_location_id,
	s.first_opt_in_date	   = temp.first_opt_in_date,
	s.last_opt_in_location_id  = temp.last_opt_in_location_id,
	s.last_opt_in_date	   = temp.last_opt_in_date,
	s.last_wm_scan_date   	   = temp.last_wm_scan_date,
	s.last_sc_scan_date	   = temp.last_sc_scan_date;

	DROP TABLE dwa.scans_by_fmi_temp_;		
	";

 mailx -v -A freeosk -s "CMS Phase 1 Done" -a /root/script/scans_by_fmi_temp.log  mikael.houndegnon@thefreeosk.com <<< "Done"

