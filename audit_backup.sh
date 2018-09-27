
usage() {
        echo "usage: ./$(basename $0) [prod or ods]"
}


if [ $# -eq 0 ]
then
        usage
        exit 1
fi

path="/var/mysql_audit_log/"
case $1 in
        "prod")
		backup_path="/var/dwbi/mysql_audit_backup/prod/"$(date +'%Y-%m')"/"
        ;;
        "ods")
		backup_path="/var/dwbi/mysql_audit_backup/ods/"$(date +'%Y-%m')"/"
        ;;
	"pii")
                backup_path="/var/dwbi/mysql_audit_backup/pii/"$(date +'%Y-%m')"/"
        ;;
	*) 
		echo "invalid option" 
		exit 0 
	;;
esac
cd $path
file_format="server_audit.log.*"

for old_file in $file_format
do
	new_file="server_audit_"$(date -r $old_file +'%Y-%m-%d-%H-%M-%S')".log.gz"
	gzip $old_file
	mv $old_file".gz" $new_file
	{ echo -mkdir $backup_path; } | sftp root@192.168.157.200
	sftp root@192.168.157.200:$backup_path <<< $'put *.gz*'
	rm -rf $new_file
done
exit 0
