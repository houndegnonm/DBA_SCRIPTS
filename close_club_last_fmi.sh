
mysql -u mhoundegnon -p"PasS123" -e "create table dwa.last_scan_by_fmi_from_close_to_open_club as select ods_scan_data.fmi, max(ods_scan_data.scan_time) as last_scan_time, ods_scan_data.date_scanned 
from dwa.last_scan_by_fmi_closed_club  lfck
JOIN ods.ods_scan_data ON ods_scan_data.fmi=lfck.fmi
WHERE ods_scan_data.scan_time > lfck.last_scan_time
group by ods_scan_data.fmi;"

lx -v -A freeosk -s "table dwa.last_scan_by_fmi_from_close_to_open_club is ready "  mikael.houndegnon@thefreeosk.com  <<< "Done"
