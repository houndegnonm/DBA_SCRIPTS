
usage() {
        echo "usage: ./$(basename $0) [qa or prod or edw or ods]"
}

fix_error() {
        mysql -u mhoundegnon -p"PasS123" -e"show slave status \G" > install_error.log
        error=$(cat /root/script/install_error.log | grep Slave_SQL_Running: | sed 's/[:] */&\n/g' | tail -n 1)
        last_error=$(cat /root/script/install_error.log | grep Last_Error)
        while [ "$error" = "No" ]
        do
                echo $last_error
                mysql -u mhoundegnon -p"PasS123" -e"STOP SLAVE;"
                mysql -u mhoundegnon -p"PasS123" -e"SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1;"
                mysql -u mhoundegnon -p"PasS123" -e"START SLAVE;"
                error=$(mysql -u mhoundegnon -p"PasS123" -e"show slave status \G" | grep Slave_SQL_Running: | sed 's/[:] */&\n/g' | tail -n 1)
        done
        exit 1
}


# this function is called when Ctrl-C is sent
function trap_ctrlc ()
{
    # perform cleanup here
    echo "Ctrl-C caught...performing clean up"
 
    echo "Doing cleanup"
 
    # exit shell script with error code 2
    # if omitted, shell script will continue execution
    exit 2
}

drop_slave() {
	sudo /etc/init.d/mysqld stop
        sudo yum remove Percona-Server*
        sudo yum remove mysql-community*
	rm -rf /var/lib/mysql
        rm -f /etc/my.cnf
        rm -rf /etc/percona-server.conf.d
        rm -f /var/log/mysqld.log
        rm -f /var/log/mysql/mysqld_error.log
        sudo yum remove pmm-client
}

check_replication_status(){
	MSG=`mysql -u mhoundegnon -p"PasS123" -e 'show slave status\G' | grep Last_SQL_Error | sed -e 's/ *Last_SQL_Error: //'`
	IO_IS_RUNNING=`mysql -u mhoundegnon -p"PasS123" -e "SHOW SLAVE STATUS\G" | grep "Slave_IO_Running" | awk '{ print $2 }'`
	SQL_IS_RUNNING=`mysql -u mhoundegnon -p"PasS123" -e "SHOW SLAVE STATUS\G" | grep "Slave_SQL_Running" | awk '{ print $2 }' | head -1`
	#check to see if msg string has length non zero

	if [ $IO_IS_RUNNING = "Yes" ] && [ $SQL_IS_RUNNING = "Yes" ]; then
		mailx -v -A freeosk -s "Monitoring of $server slave status : [OK]" mikael.houndegnon@thefreeosk.com db_support@thefreeosk.com <<< "Slave has read all relay log; waiting for more updates"
	else
                mailx -v -A freeosk -s "Monitoring of $server slave status : [ERROR]" mikael.houndegnon@thefreeosk.com  db_support@thefreeosk.com  <<< "Error Message : $MSG

# Please run : [./$(basename $0) $server repair] to fix any errors"
	fi
	exit 0
}



replication_validation(){
	#enter the database in which the table should be created
	db1="test_replication"
	#enter the table that is created in master
	table1="test_table"
	
	log="/root/script/replication_check.log"
	rm -rf $log
	touch $log
	
	start="$(date +'%Y-%m-%d %T')"
	echo " " >>$log
	echo " " >>$log
	echo "The replication check started between $master and $slave at $start" >>$log
	echo " " >>$log
	echo " " >>$log

	#-----------------Database check-------------------
	mysql -h$host1 -u$user1 -p$password1 -se "create database $db1;"
	db1_chk=$(mysql -h$host1 -u$user1 -p$password1 -se "show databases like '$dba1';")
	if [ "$db1_chk" != "$db1" ]; then
        	echo "Database - $db1 has been created in $master" >>$log
	        chk1="yes"
        else
                echo "Database - $db1 could not be created in $master" >>$log
                chk1="no"
	fi
	echo " " >>$log
	echo " " >>$log
	sleep 15s
	db2_chk=$(mysql -h$host2 -u$user2 -p$password2 -se "show databases like '$dba1';")
	if [ "$db2_chk" != "$db1" ]; then
        	echo "Database - $db1 has been created in $slave" >>$log
	        chk2="yes"
        else
                echo "Database - $db1 could not be created in $slave">>$log
                chk2="no"
	fi
	
	#----------------Table create check
	echo " " >>$log
	echo " " >>$log
	mysql -h$host1 -u$user1 -p$password1 -se "use $db1;create table $table1 (id varchar(255),name varchar(255));"
	tab_chk1=$(mysql -h$host1 -u$user1 -p$password1 -se "use $db1;show tables like '$table1';")
	if [ "$tab_chk1" = "$table1" ]; then
        	echo "Table - $table1 has been created in $master">>$log
	        chk3="yes"
        else
        	echo "Table - $table1 could not be created in $master">>$log
	        chk3="no"
	fi
	echo " " >>$log
	echo " " >>$log
	sleep 15s
	tab_chk2=$(mysql -h$host2 -u$user2 -p$password2 -se "use $db1;show tables like '$table1';")
	if [ "$tab_chk2" = "$table1" ]; then
        	echo "Table - $table1 has been created in $slave">>$log
	        chk4="yes"
        else
        	echo "Table - $table1 could not be created in $lave">>$log
	        chk4="no"
	fi

	#----------------Table count check
	echo " " >>$log
	echo " " >>$log
	mysql -h$host1 -u$user1 -p$password1 -se "use $db1;INSERT INTO $table1(id,name)VALUES(1,'english'),(2,'italian'),(3,'german'),(4,'japanese'),(5,'Mandarin');"
	tab_count1=$(mysql -h$host1 -u$user1 -p$password1 -se "use $db1; select count(*) from $table1;")
	echo "$tab_count1 rows are inserted into $db1.$table1 of $master">>$log
	echo " " >>$log
	echo " " >>$log
	sleep 15s
	tab_count2=$(mysql -h$host1 -u$user2 -p$password2 -se "use $db1;select count(*) from $table1;")
	if [ "$tab_count1"="$tab_count2" ]; then
        	echo "Row count is matching between $master and $slave">>$log
	        chk5="yes"
        else
                echo "Row count is not matching">>$log
                chk5="no"
	fi

	#--------------drop table check
	echo " " >>$log
	echo " " >>$log
	mysql -h$host1 -u$user1 -p$password1 -se "use $db1;drop table $table1;"
	tab_chk1=$(mysql -h$host1 -u$user1 -p$password1 -se "use $db1;show tables like '$table1';")
	if [ "$tab_chk1"!="$table1" ]; then
	       echo "database - $db1 has been dropped in $master">>$log
	       else
	       echo "database - $db1 could not be dropped in $master">>$log
	fi
	echo " " >>$log
	echo " " >>$log
	sleep 15s
	tab_chk2=$(mysql -h$host2 -u$user2 -p$password2 -se "use $db1;show tables like '$table1';")
	if [ "$tab_chk2"!="$table1" ]; then
	       echo "database - $db1 has been dropped in $slave">>$log
	       else
	       echo "database - $db1 could not be dropped in $slave">>$log
	fi

	#----------------drop database check

	echo " " >>$log
	echo " " >>$log
	mysql -h$host1 -u$user1 -p$password1 -se "drop database $db1;"
	tab_chk1=$(mysql -h$host1 -u$user1 -p$password1 -se "show databases like '$dba1';")
	if [ "$tab_chk1"!="$db1" ]; then
        	echo "database - $db1 has been dropped in $master">>$log
	        chk6="yes"
        else
	        echo "database - $db1 could not be dropped in $master">>$log
	        chk6="no"
	fi
	echo " " >>$log
	echo " " >>$log
	sleep 15s
	tab_chk2=$(mysql -h$host2 -u$user2 -p$password2 -se "show databases like '$dba1';")
	if [ "$tab_chk2"!="$db1" ]; then
        	echo "database - $db1 has been dropped in $slave">>$log
	        chk7="yes"
        else
        	echo "database - $db1 could not be dropped in $slave">>$log
	        chk7="no"
	fi
	end="$(date +'%Y-%m-%d %T')"
	echo " " >>$log
	echo " " >>$log
	echo "The replication check ended between $master and $slave at $end" >>$log

	#-----------------sending email
	var="yes"
	if [[ "$chk1" == "$var" ]] && [[ "$chk2"=="$var" ]] && [[ "$chk3" == "$var" ]] && [[ "$chk4" == "$var" ]] && [[ "$chk5" == "$var" ]] && [[ "$chk6" == "$var" ]] && [[ "$chk7" == "$var" ]];then
	        subject="Replication Successful - ($master & $slave)"
        	message="Please refer to the log file for replication results"
	        mailx -v -A freeosk -s "$subject" -a $log mikael.houndegnon@thefreeosk.com db_support@thefreeosk.com  <<< "$message"
	else
	        subject="Replication Unsuccessful - ($master & $slave)"
	        message="Please refer to the log file for replication results"
	        mailx -v -A freeosk -s "$subject" -a $log mikael.houndegnon@thefreeosk.com db_support@thefreeosk.com  <<< "$message"
	fi

	rm -rf $log
}



data_validation(){
	#-------------------script do not change any code below this line----------------------------------------
	today="$(date +'%Y-%m-%d')"
	todayStartTime="$(date +'%Y-%m-%d') 00:00:00"
	todayEndTime="$(date +'%Y-%m-%d') 23:59:59"
	start="$(date +'%Y-%m-%d %T')"
	file="DATA_VAL_$(date +'%Y-%m-%d').log"
	
	log="/root/script/DATA_VAL_$(date +'%Y-%m-%d').log"
	rm -rf $log
	touch $log
	#----------------------master------------------------------
	start="$(date +'%Y-%m-%d %T')"
	echo "                 " >>$log
	echo "                 " >>$log
	echo "The Data validation check started between $master and $slave at $start" >>$log
	echo "                        " >>$log
	echo "------------------------$master-----------------" >>$log
	Table_count1=$(mysql -h$host1 -u$user1 -p$password1 -se "SELECT count(*)FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE';")
	echo "Table count of $master is $Table_count1" >>$log
	View_count1=$(mysql -h$host1 -u$user1 -p$password1 -se " SELECT count(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='view';")
	echo "View count of $master is $View_count1" >>$log
	sp1=$(mysql -h$host1 -u$user1 -p$password1 -se "select count(*) from INFORMATION_SCHEMA.routines;")
	echo "Stored procedures count of $master is $sp1" >>$log
	Triggers_count1=$(mysql -h$host1 -u $user1 -p$password1 -se "select count(*) from INFORMATION_SCHEMA.triggers;")
	echo "triggers count of $master is $Triggers_count1" >>$log
	user_count1=$(mysql -h$host1 -u$user1 -p$password1 -se " select count(*) from mysql.user;")
	echo "USER count of $master is $user_count1" >>$log
	User_priv1=$(mysql -h$host1 -u$user1 -p$password1 -se "select count(*) from INFORMATION_SCHEMA.USER_PRIVILEGES;")
	echo "USER PRIVILEGES count of $master is $User_priv1" >>$log

	#----------------------slave------------------------------
	echo "----------------- $server SLAVE -----------------------------------------" >>$log
	Table_count2=$(mysql -h$host2 -u$user2 -p$password2 -se "SELECT count(*)FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE';")
	echo "Table count of $slave is $Table_count2" >>$log
	View_count2=$(mysql -h$host2 -u$user2 -p$password2 -se " SELECT count(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='view';")
	echo "View count of $slave is $View_count2" >>$log
	sp2=$(mysql -h$host2 -u$user2 -p$password2 -se "select count(*) from INFORMATION_SCHEMA.routines;")
	echo "Stored procedures count of $slave is $sp2" >>$log
	Triggers_count2=$(mysql -h$host2 -u$user2 -p$password2 -se "select count(*) from INFORMATION_SCHEMA.triggers;")
	echo "triggers count of $slave is $Triggers_count2" >>$log
	user_count2=$(mysql -h$host2 -u$user2 -p$password2 -se " select count(*) from mysql.user;")
	echo "USER count of $slave is $user_count2" >>$log
	User_priv2=$(mysql -h$host2 -u$user2 -p$password2 -se "select count(*) from INFORMATION_SCHEMA.USER_PRIVILEGES;")
	echo "USER PRIVILEGES count of $slave is $User_priv2" >>$log

	finish="$(date +'%Y-%m-%d %T')"
	echo "                 " >>$log
	echo "                 " >>$log
	echo "The Data validation check between $master and $slave slave finished at $finish" >>$log
	echo "                 " >>$log
	echo "                 " >>$log

	#sending email with log file attached
	if [[ "$Table_count1" == "$Table_count2" ]] && [[ "$View_count1" == "$View_count2" ]] && [[ "$sp1" == "$sp2" ]] && [[ "$Triggers_count1" == "$Triggers_count2" ]] && [[ "$User_priv1" == "$User_priv2" ]]; then
        	echo " Result: Data validation is complete and all counts are matching" >>$log
	        subject="Successful - Data Validation($master & $slave)- counts match"
        	message='All counts are matching. Please review the attached log file'
	      	mailx -v -A freeosk -s "$subject" -a $log db_support@thefreeosk.com mikael.houndegnon@thefreeosk.com  <<< $message
	else
                message="/var/DATA_VAL_message.txt"
                touch $message
                echo "The below statements are the mismatches between $master and $slave" >>$message
                if [[ $Table_count1!=$Table_count2 ]]; then
                        echo "Table count doesn't match" >>$message
                fi
                if [[ $View_count1!=$View_count2 ]]; then
                        echo "View count doesn't match" >>$message
                fi
                if [[ $sp1!=$sp2 ]]; then
                                echo "stored procedures doesn't match" >>$message
                fi
                if [[ $Triggers_count1!=$Triggers_count2 ]]; then
                        echo "trigger count doesn't match" >>$message
                fi
                if [[ $User_priv1!=$User_priv2 ]]; then
                        echo "user Privileges doesn't match" >>$message
                fi

        	echo "Result: Data validation is complete and there are mismatches in the counts" >>$log
	        subject="Unsuccessful - Data Validation($master & $slave) - counts mismatch"
        	mailx -v -A freeosk -s "$subject" -a $log db_support@thefreeosk.com mikael.houndegnon@thefreeosk.com  <<< $message
        	rm -rf $message
	fi
	rm -rf $log

}


setup_slave() {
	echo "" >  /root/script/install.log
	echo "--------- $(date) Begin Package Installation : set Master to $ip_address " >> /root/script/install.log
	# sudo yum remove Percona-Server*
	rpm -e --nodeps  Percona-Server*
	sudo yum install pmm-client
	rm -f /etc/my.cnf
	sudo yum localinstall https://dev.mysql.com/get/mysql57-community-release-el6-11.noarch.rpm
	sudo yum -x Percona-Server-* install mysql-community-server
	sudo yum -x Percona-Server-* install percona-xtrabackup-24
	echo "--------- $(date) End of Package Installation " >> /root/script/install.log

	echo "--------- $(date) Start MySQL Service " >> /root/script/install.log
        sudo /etc/init.d/mysqld start >> /root/script/install.log

	password=$(cat  /var/log/mysqld.log  | grep "A temporary password is generated for root@localhost:" | sed 's/[ ] */&\n/g' | tail -n 1)
	mysql --connect-expired-password -u root -p"$password" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'DV17Nol@nn' ; FLUSH PRIVILEGES;"

	echo "--------- $(date) Stop MySQL Service " >> /root/script/install.log
        sudo /etc/init.d/mysqld stop >> /root/script/install.log

	echo "--------- $(date) Prepare the log File " >> /root/script/install.log
	sudo rm -rf /var/log/mysql/*
	sudo mkdir -p /var/log/mysql/
	sudo touch /var/log/mysql/mysql-error.log
	sudo chown -R mysql:mysql /var/log/mysql/

	echo "--------- $(date) Replace the default my.cnf " >> /root/script/install.log
	mv /etc/my.cnf /etc/my.cnf.old
	cp /root/script/$server.cnf /etc/my.cnf

	echo "--------- $(date) Restart MySQL service " >> /root/script/install.log
        sudo /etc/init.d/mysqld restart >> /root/script/install.log
	sudo /etc/init.d/mysqld stop >> /root/script/install.log
	
	echo "--------- $(date) Stop MySQL service " >> /root/script/install.log

	echo "--------- $(date) Clean mysql data directory " >> /root/script/install.log
	rm -rf /var/lib/mysql.back
	cp -r  /var/lib/mysql /var/lib/mysql.back
	rm -rf /var/lib/mysql/*
	cp -r  /var/db_backups/full/* /var/lib/mysql

	echo "--------- $(date) Change data directory owner to mysql " >> /root/script/install.log
	sudo chown -R mysql:mysql /var/lib/mysql

	echo "--------- $(date) Start MySQL service " >> /root/script/install.log	
        sudo /etc/init.d/mysqld start >> /root/script/install.log

	echo "--------- $(date) Set Master DB binary log file and position " >> /root/script/install.log
	file=$(cat /root/script/master.info | grep File | sed 's/[:] */&\n/g' | tail -n 1)
	position=$(cat /root/script/master.info | grep Position | sed 's/[:] */&\n/g' | tail -n 1)

	echo "--------- $(date) Setup Slave " >> /root/script/install.log
	mysql -u mhoundegnon -p"PasS123" -e "CHANGE MASTER TO MASTER_HOST='$ip_address',MASTER_USER='slave_user', MASTER_PASSWORD='DV17Nol@nn', MASTER_LOG_FILE='$file', MASTER_LOG_POS=$position ; "

	echo "--------- $(date) Start Slave " >> /root/script/install.log
	mysql -u mhoundegnon -p"PasS123" -e "START SLAVE;"
	# fix_error >> /root/script/install.log
	echo "--------- $(date) End " >> /root/script/install.log

	sudo pmm-admin config --server 192.168.147.11:8080 --server-user pmm --server-password AR627PxmuFMZx2x7
	sudo pmm-admin add mysql --user pmm --password 'PasS123' --disable-tablestats-limit 9999
}

server=$1
action=$2

# initialise trap to call trap_ctrlc function
# when signal 2 (SIGINT) is received
trap "trap_ctrlc" 2


if [ $# -eq 0 ]
then
        usage
        exit 1
fi

case $server in
        "qa")
                ip_address="69.40.217.151"
		ip_slave="192.168.157.102"
        ;;
        "prod")
                ip_address="69.40.217.151"
        ;;
        "edw")
                ip_address="69.40.217.151"
        ;;
        "ods")
                ip_address="69.40.217.151"
        ;;
        *) 
		echo "invalid option"
		exit 0
	;;
esac



# validation variables
user2="mhoundegnon"
host2=$ip_slave
password2="PasS123"

user1="mhoundegnon"
host1=$ip_address
password1="PasS123"

master=$server
slave=" $server slave "



case $action in
        "repair")
                fix_error
        ;;
        "setup")
                setup_slave
		mailx -v -A freeosk -s "$server databse migration step 2 is complete " -a /root/script/install.log  mikael.houndegnon@thefreeosk.com db_support@thefreeosk.com  <<< "$server slave database is ready. Below the next steps :
- Sync should start automaticall if is not the case please check the status of the slave by running : [./$(basename $0) $server replica_status] 
- To fix any errors run : [./$(basename $0) $server repair]
- Validate the Master Slave by using the validate option i.e [./$(basename $0) $server validate] 

"
        ;;
        "drop")
                drop_slave
        ;;

	"replica_status")
               check_replication_status
        ;;
	
	"validate_data")
	        data_validation
	;;
	
	"validate_replication")
                replication_validation
        ;;

        *) 
		echo "invalid option"
		exit 0
	;;

	
esac

