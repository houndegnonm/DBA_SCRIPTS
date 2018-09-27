
if [ $# -eq 0 ]
then
       	echo "Missing Date Parameter yyyy-mm-dd exit."
        exit 1
fi

exit

FTP_PATH="/home/cli/freeosk_scp/Freeosk_Upload/"
FTP_USER="freeosk_scp"
FTP_HOST="files.responsys.net"
FTP_KEY_FILE="/root/.ssh/ri_key.ppk"

DB_USER="mhoundegnon"
DB_PWD="PasS123"
DB_NAME="temp_db"
TABLE="fmi_activity"

FILE_NAME="/var/lib/mysql-files/fmi_activity_history_$( date '+%Y%m%d_%H%M%S' ).txt"
TEMP_FILE_NAME="/var/lib/mysql-files/tempfile.txt"

rm -rf $TEMP_FILE_NAME

#(1)creates empty file and sets up column names using the information_schema
mysql -u$DB_USER -p$DB_PWD $DB_NAME -B -e "SELECT COLUMN_NAME FROM information_schema.COLUMNS C WHERE table_name = '$TABLE' AND COLUMN_NAME NOT IN ('db_created_at','db_updated_at','db_created_time','db_updated_time') ORDER BY ORDINAL_POSITION ASC" | awk '{print $1}' | grep -iv ^COLUMN_NAME$ | sed 's/^/"/g;s/$/"/g' | tr '\n' ',' > $FILE_NAME

sed -i 's/,$//' $FILE_NAME

#(2)appends newline to mark beginning of data vs. column titles
echo "" >> $FILE_NAME

#(3)dumps data from DB into /var/mysql/tempfile.csv
mysql -u$DB_USER -p$DB_PWD $DB_NAME -B -e " 
	SELECT
			fmi_activity.fmi,
			IF(fmi_activity.first_scan ='0000-00-00', '', fmi_activity.first_scan) first_scan,
			IF(fmi_activity.last_scan ='0000-00-00', '',fmi_activity.last_scan) last_scan,
			fmi_activity.total_scans,
			fmi_activity.total_days,
			fmi_activity.scan_cycle,
			fmi_activity.no_of_programs,
			fmi_activity.no_of_kiosks,
			fmi_activity.home_location_id,
			fmi_activity.home_location_name,
			IF(fmi_activity.home_location_open IS NULL,'',home_location_open) home_location_open,
			fmi_activity.first_scan_location_id,
			fmi_activity.first_scan_location_name,
			fmi_activity.last_scan_location_id,
			fmi_activity.last_scan_location_name,
			IF( fmi_activity.first_opt_in_location_id IS NULL,'',first_opt_in_location_id) first_opt_in_location_id,
			IF(fmi_activity.first_opt_in_location_name IS NULL ,'',first_opt_in_location_name) first_opt_in_location_name,
			IF(fmi_activity.first_opt_in_date IS NULL OR fmi_activity.first_opt_in_date='0000-00-00','',first_opt_in_date) first_opt_in_date,
			IF(fmi_activity.last_opt_in_location_id IS NULL,'',last_opt_in_location_id) last_opt_in_location_id,
			IF(fmi_activity.last_opt_in_location_name IS NULL,'',last_opt_in_location_name) last_opt_in_location_name,
			IF(fmi_activity.last_opt_in_date IS NULL  OR fmi_activity.last_opt_in_date='0000-00-00','',last_opt_in_date) last_opt_in_date,
			IF(fmi_activity.home_opt_in_location_id IS NULL, '', home_opt_in_location_id) home_opt_in_location_id,
			IF(fmi_activity.home_opt_in_location_name IS NULL,'',home_opt_in_location_name) home_opt_in_location_name,
			IF(fmi_activity.has_email IS NULL,'',has_email) has_email,
			IF(fmi_activity.email_capture_source IS NULL,'',email_capture_source) email_capture_source,
			IF(fmi_activity.has_mobile IS NULL, '', has_mobile) has_mobile,
			IF(fmi_activity.last_wm_scan_date = '0000-00-00', '',last_wm_scan_date) last_wm_scan_date,
			IF(fmi_activity.last_sc_scan_date = '0000-00-00','',last_sc_scan_date) last_sc_scan_date
	INTO OUTFILE '$TEMP_FILE_NAME' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' 
	FROM $TABLE
	WHERE has_email='YES'
	AND (
		 	db_created_at 	='$1'
		OR 	db_updated_at   ='$1'
	)
	;"

#(4)merges data file and file w/ column names
cat $TEMP_FILE_NAME >> $FILE_NAME

echo " put $FILE_NAME $FTP_PATH " | sftp -oIdentityFile="$FTP_KEY_FILE" $FTP_USER@$FTP_HOST

mailx -v -A freeosk -s "EXPORT IS Done" mikael.houndegnon@thefreeosk.com <<< "DONE"
# mailx -v -A freeosk -s "EXPORT IS Done" mikael.houndegnon@thefreeosk.com viral.mehta@thefreeosk.com <<< "DONE"

