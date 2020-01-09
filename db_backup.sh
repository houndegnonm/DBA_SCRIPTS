user="mhoundegnon"
pwd=""
meta_host="192.168.157.106"
folderName=$( date '+%Y-%m-%d' )
file_prefix=$( date '+%Y' )


inserted_id=$(mysql -u$user -p$pwd -h$meta_host -se"insert into meta_shcema.backup_summary (system,backupStartDate) value ('$1',now()); SELECT LAST_INSERT_ID(); ") # DB LOG

full_size=$(du -cs /var/lib/mysql | cut -f1| head -1)
sudo innobackupex --user=mhoundegnon --password=PasS123 --no-lock --history --parallel=4  --stream=xbstream ./ | ssh root@192.168.157.200 " pigz -1 -p 1  - > /var/dwbi/mysql_db_backup/$1/$folderName.xbstream.gz; " 

# DB LOG
if [[ $? -eq 0 ]]; then
	compress_size=$(ssh root@192.168.157.200 "du -cs /var/dwbi/mysql_db_backup/$1/$folderName.xbstream.gz | cut -f1| head -1")
	mysql -u$user -p$pwd -h$meta_host -e"UPDATE meta_shcema.backup_summary SET 
							backupEndDate=now(),
							uncompressedSize='$full_size', 
							backupSuccess=1, 
							compressedSize='$compress_size' 
						WHERE id='$inserted_id' AND system='$1';  " 
	ssh root@192.168.157.200 "find /var/dwbi/mysql_db_backup/$1/$file_prefix*.gz -mtime +5 -type f -delete "
	mailx -v -A freeosk -s "$( date '+%Y-%m-%d' ) $1 DB Full Backup is completed"  mikael.houndegnon@thefreeosk.com viral.mehta@thefreeosk.com  <<< "$1 DB Full Backup is successfully completed for $( date '+%Y-%m-%d' ), check meta_shcema.backup_summary table for more details "
else 
	mysql -u$user -p$pwd -h$meta_host -e"UPDATE meta_shcema.backup_summary SET 
							backupEndDate=now(),
							uncompressedSize='$full_size' 
						WHERE id='$inserted_id' AND system='$1';  " 
	mailx -v -A freeosk -s "$( date '+%Y-%m-%d' ) $1 DB Full Backup Dump failed"  mikael.houndegnon@thefreeosk.com viral.mehta@thefreeosk.com  <<< "$1 DB Full Backup dump failed for $( date '+%Y-%m-%d' ) check meta_shcema.backup_summary table for more details "
	exit 1
fi

