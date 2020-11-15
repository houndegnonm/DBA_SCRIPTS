#
# USAGE : add_intraday_incremental.sh  <OPTIONAL  backup basedir location>  <REQUIRED intraday backup directory with week> 
# if no parameter passed for directory base directory the default hardcoded value will be used
# if no parameter passed for the required backup directory, exit.
#
# Set up a few defaults
#
backup_src_dir="$1";
intraday_dir="$2";

start=$(date +"START: %D %T %Z")

if [ -z "$backup_src_dir" ];
then
    backup_src_dir="/sql-backups/sqldr-dev01/";
fi;

if [[ -z "$intraday_dir" ]] ; then 
	echo "BACKUP DIRECTORY location is a required parameter"
        end=$(date +"END: %D %T %Z")

        echo " Intra Restore  completed : $start  $end"
        exit 1
fi;


mysqlpid=$(pidof  /usr/sbin/mysqld )


#echo "msql pid is $mysqlpid" 
#echo "srcdir is $backup_src_dir"
#echo "intraday is $intraday" 
full_src_dir="$backup_src_dir/$intraday_dir"
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
### Xtrabackup alters the binary log file (xtrabackup_logfile)  that is used when the restore is processed. Therefore, this means that
### that if we restore a specific intra day backup to a weekly + daily  and then re-restore the intra day backup, we can not go back
### to square one and start over again... because the incremental  has already been processed.
### therefore, let's make a copy of it so that we have an original...
### If the backup copy already exists, then let's copy it to the filename that xtrabackup wants to use.
             echo "checking for existance of xtrabackup_logfile_bak "
             binlog_name="${full_src_dir}/xtrabackup_logfile"
             binlog_backup="${binlog_name}_bak"
echo "binlog_name = >$binlog_name< and backup is >$binlog_backup<"
             if [[ -f $binlog_backup ]] ; then
## Copy the backup to the source and proceed.
                echo "Copying backup of ${binlog_name} to original"
                cp --preserve -f $binlog_backup $binlog_name

             else
## Make a copy of the binary log file (binlog_name) and proceed
                echo "Making a copy of the original ${binlog_name}"
                cp --preserve -f $binlog_name $binlog_backup
             fi

### and if we're successful, then prepare the backup 
             echo "I want to prepare incremental restore targetting  $mysqldatadir with $full_src_dir"
             xtrabackup  --use-memory=4GB  --prepare --apply-log-only --target-dir=$mysqldatadir   --keyring-file-data=$mysqlkeyring --incremental-dir=$full_src_dir
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

echo " Intraday PREP of backup completed : $start  $end" 
