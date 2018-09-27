#!/bin/bash

set -e #stops execution if a variable is not set
set -u #stop execution if something goes wrong

usage() { 
        echo "usage: $(basename $0) [option]" 
        echo "option=full: do a full backup of all databases."
        echo "option=incremental: do a incremental backup"
        echo "option=help: show this help"
}

full_backup() {
	date	
	sudo innobackupex $ARGS  ./ | ssh root@192.168.147.17 "cat - > $BACKUP_DIR/full_backup_$( date '+%Y-%m-%d' ).xbstream" 
	date
}


incremental_backup()
{
	date
	echo "Connect to PERCONA_SCHEMA.xtrabackup_history and get the last incremental lsn"
	
	last_full_time=$(mysql -u$USER -p$PWD -se "SELECT start_time FROM PERCONA_SCHEMA.xtrabackup_history where incremental='N' order by start_time desc limit 1;")
	
	if [ -z  "$last_full_time" ]
	then
		echo "ERROR: no full backup has been done before. aborting"
		exit -1
	fi 

	inc_num=$(mysql -u$USER -p$PWD -se "select count(*)+1  from PERCONA_SCHEMA.xtrabackup_history where incremental='Y' and start_time >= '$last_full_time' ;")

	last_lsn=$(mysql -u$USER -p$PWD -se "select innodb_to_lsn  from PERCONA_SCHEMA.xtrabackup_history order by start_time desc limit 1;")
	
	sudo innobackupex $ARGS --incremental --incremental-lsn=$last_lsn ./ | ssh root@192.168.147.17 "cat - > $BACKUP_DIR/incremental_backup_'$inc_num'_$( date '+%Y-%m-%d' ).xbstream"
	date
}

#START HERE
BACKUP_DIR=/var/db_backups/prod_backups
USER="db-user"
PWD='db-pwd'
ARGS=" --user=$USER --password=$PWD --no-lock --history --stream=xbstream  "

if [ $# -eq 0 ]
then
usage
exit 1
fi
    case $1 in
        "full")
            full_backup
            ;;
        "incremental")
        incremental_backup
            ;;
        "help")
            usage
            #break
            ;;
        *) echo "invalid option";;
    esac
