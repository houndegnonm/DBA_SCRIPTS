#
# USAGE : move_and_prepare_backup.sh  <optional backup basedir location> <optional week name>
# if no parameter passed for directory base directory the default  hard coded below is used
# if no parameter passed for the optional weekname then the current week is calculated and used.
#
# Set up a few defaults
#
backup_src_dir="$1";
weekly_name="$2";

start=$(date +"START: %D %T %Z")

if [ -z "$backup_src_dir" ];
then
    backup_src_dir="/sql-backups/sqldr-dev01/";
fi;

if [[ -z "$weekly_name" ]] ; then 
	weekly_name=$(date "+%G-W%U");
fi;

mysqlpid=$(pidof  /usr/sbin/mysqld )


#echo "msql pid is $mysqlpid" 
#echo "srcdir is $backup_src_dir"
#echo "weekly_name is $weekly_name" 
full_src_dir="$backup_src_dir/$weekly_name/weekly"
#echo "and the full sourcedir is $full_src_dir"

if [[ -z $mysqlpid ]] ;  then 
   echo "MySQL not running... Continuing" 
   ##mysql not running so we need to figure out
# where the data directory and keyring locations are 
# figure out which week we're looking at to move
# move the weekly backup from that weekly directory to the datadir directory ... 
# using RSYNC with DELETE just in case
# use xtrabackup to prepare the weekly so that another one can be applied.

    mysqldatadir=$(grep datadir  /etc/my.cnf | awk '{split($0,parts,"=") ; gsub(/^[ \t]+|[ \t]+$/, "", parts[2]) ;print parts[2]; }' )
    mysqlkeyring=$(grep keyring_file_data /etc/my.cnf | awk '{split($0,parts,"=") ;gsub(/^[ \t]+|[ \t]+$/, "", parts[2]) ; print parts[2]; }')

    if [ ! -d $mysqldatadir ] ; then 
        echo "Unable to determine MySQL data directory $mysqldatadir ... Aborting" ; 
    else 
        echo "Using MySQL data directory : $mysqldatadir" ; 
        echo "Will use the keyring file located in : $mysqlkeyring"; 
# and now determine the week we're in.  Allow it to be passed in if we need to revert a specific week (hopefully it's still on the server)
#       echo "testing to see if the data is really there in $full_src_dir"
        if [[ ! -d $full_src_dir ]] ; then 
            echo "Unable to find $full_src_dir.... Aborting" ; 
        else
# and so, we have a src, a destination, let's rsync that data . 
            rsync_cmd="rsync  --delete -avh $full_src_dir/  $mysqldatadir "
            echo "Executing $rsync_cmd"
            `$rsync_cmd`  > rsync.log
### put error checking in ... 

### and if we're successful, then prepare the backup 
            xtrabackup  --use-memory=4GB  --prepare --apply-log-only --target-dir=$mysqldatadir   --keyring-file-data=$mysqlkeyring
#### put error checking in 

### and change the ownership from Root to MySQL ... 
            chown -R mysql:mysql $mysqldatadir
        fi
    fi  
else
   echo "MySQL running as pid >$mysqlpid<."
   echo "MySQL is running and therefore presumed to be in use for recovery. Aborting"
   completion_status="failed"
fi

end=$(date +"END: %D %T %Z")

echo " RSYNC and PREP of backup completed : $start  $end" 
