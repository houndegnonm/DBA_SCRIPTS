#
# USAGE : mysql_final_prep_and_start.sh  
# does the final xtrabackup PREP, once more confirms ownership of the files by the mysql user and starts mysql 
#

start=$(date +"START: %D %T %Z")


mysqlpid=$(pidof  /usr/sbin/mysqld )

#echo "msql pid is $mysqlpid" 

if [[ -z $mysqlpid ]] ;  then 
   echo "MySQL not running... Continuing" 
   ##mysql not running so we need to figure out
# where the data directory and keyring locations are 

    mysqldatadir=$(grep datadir  /etc/my.cnf | awk '{split($0,parts,"=") ; gsub(/^[ \t]+|[ \t]+$/, "", parts[2]) ;print parts[2]; }' )
    mysqlkeyring=$(grep keyring_file_data /etc/my.cnf | awk '{split($0,parts,"=") ;gsub(/^[ \t]+|[ \t]+$/, "", parts[2]) ; print parts[2]; }')

    if [ ! -d $mysqldatadir ] ; then 
        echo "Unable to determine MySQL data directory $mysqldatadir ... Aborting" ; 
    else 
        echo "Using MySQL data directory : $mysqldatadir" ; 
        echo "Executing final prepare  targetting  $mysqldatadir"
        xtrabackup  --use-memory=4GB  --prepare --target-dir=$mysqldatadir   --keyring-file-data=$mysqlkeyring 
#### put error checking in 

### and change the ownership from Root to MySQL ... 
        chown -R mysql:mysql $mysqldatadir
        service mysqld start 
    fi  
else
   echo "MySQL running as pid >$mysqlpid<."
   echo "MySQL is running and therefore presumed to be in use for recovery. Aborting"
   completion_status="failed"
fi

end=$(date +"END: %D %T %Z")

echo " PREP of backup completed : $start  $end" 
