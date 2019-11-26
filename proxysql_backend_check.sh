#!/bin/bash
# version: 0.1
## inspired by proxysql_galera_checker.sh
## inspired also by https://github.com/ZzzCrazyPig/proxysql_groupreplication_checker/blob/master/proxysql_groupreplication_checker.sh Frédéric -lefred- Descamps 
# 2019-11-25

function main(){
        ping_error=$($PROXYSQL_CMDLINE "select ping_error from mysql_server_ping_log where hostname='$1' order by time_start_us desc limit 1;")
        #echo "`date` ## proxysql_backend_check.sh ## ping hostName sql-dev02.dialogtech.com" >> $2
        if [[ "$ping_error" == "NULL" ]]; then
                $PROXYSQL_CMDLINE "select hostgroup_id from runtime_mysql_servers where hostname='$1' AND status='SHUNNED'" | while read hostgroup_id; 
                do
                        if [[ ! -z "$hostgroup_id"  ]]; then
                                echo "`date '+%Y-%m-%d %T'` [MONITOR - INFO] Check server $1, Status SHUNNED, hostgroup_id: $hostgroup_id, Server is now UP, changing the node to ONLINE"  >> $2
                                $PROXYSQL_CMDLINE "UPDATE mysql_servers set status='ONLINE' where hostname='$1' AND hostgroup_id='$hostgroup_id' AND status='SHUNNED'; load mysql servers to runtime;"
                        fi
                done
        else
                echo "`date '+%Y-%m-%d %T'` [MONITOR - ERROR] Check server $1, Status SHUNNED, $ping_error" >> $2
        fi
}


function usage()
{
  echo "Usage: $0 <hostname> [log_file]"
  exit 0
}

if [ "$1" = '-h' -o "$1" = '--help'  -o -z "$1" ]
then
  usage
fi

if [ $# -lt 1 ]
then
  echo "Invalid number of arguments"
  usage
fi

PROXYSQL_CMDLINE="mysql --defaults-extra-file=proxysql.cnf  -NB -e"
HOSTNAME="${1}"
ERR_FILE="${2:-/dev/null}"
main $HOSTNAME $ERR_FILE
