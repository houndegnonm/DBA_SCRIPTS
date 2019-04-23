meta_host="192.168.157.106"
folderName=$( date '+%Y-%m-%d' )
file_prefix=".xbstream"
path="/root/script"

inserted_id=$(mysql --defaults-extra-file="$path/db_backup.cnf" -h$meta_host -se"insert into meta_shcema.backup_summary (system,backupStartDate) value ('$1',now()); SELECT LAST_INSERT_ID(); ") # DB LOG

ssh root@192.168.157.200 "find /var/dwbi/mysql_db_backup/$1/*$file_prefix*.gz -mtime +4 -type f -delete "

full_size=$(du -cs /var/lib/mysql | cut -f1| head -1)
sudo innobackupex --user=db_backup --password=PasS123 --no-lock --history --parallel=4  --stream=xbstream ./ | ssh root@192.168.157.200 " pigz -1 -p 1  - > /var/dwbi/mysql_db_backup/$1/$folderName.xbstream.gz; " 

# DB LOG
if [[ $? -eq 0 ]]; then
        compress_size=$(ssh root@192.168.157.200 "du -cs /var/dwbi/mysql_db_backup/$1/$folderName.xbstream.gz | cut -f1| head -1")
        previous_compressed_size=$(mysql  --defaults-extra-file="$path/db_backup.cnf" -h$meta_host -se" SELECT round(compressedSize*0.8,0) FROM meta_shcema.backup_summary where backupSuccess=1 AND system='$1' order by backupStartDate desc limit 1;  ")

        if [[ $compress_size -ge $previous_compressed_size ]]; then
                backupSuccess=1
                msg="is successfully completed"
        else
                backupSuccess=0
                msg="Failed"
        fi

        mysql  --defaults-extra-file="$path/db_backup.cnf" -h$meta_host -e"UPDATE meta_shcema.backup_summary SET
                                                        backupEndDate=now(),
                                                        uncompressedSize='$full_size',
                                                        backupSuccess='$backupSuccess',
                                                        compressedSize='$compress_size'
                                                WHERE id='$inserted_id' AND system='$1';  "

        mailx -v -A freeosk -s "$( date '+%Y-%m-%d' ) $1 DB Full Backup $msg "  mikael.houndegnon@thefreeosk.com viral.mehta@thefreeosk.com  <<< "$1 DB Full Backup $msg for $( date '+%Y-%m-%d' ), check meta_shcema.backup_summary table for more details "
else
        mysql  --defaults-extra-file="$path/db_backup.cnf" -h$meta_host -e"UPDATE meta_shcema.backup_summary SET
                                                        backupEndDate=now(),
                                                        uncompressedSize='$full_size'
                                                WHERE id='$inserted_id' AND system='$1';  "
        mailx -v -A freeosk -s "$( date '+%Y-%m-%d' ) $1 DB Full Backup Dump failed"  mikael.houndegnon@thefreeosk.com viral.mehta@thefreeosk.com  <<< "$1 DB Full Backup dump failed for $( date '+%Y-%m-%d' ) check meta_shcema.backup_summary table for more details "
        exit 1
fi
