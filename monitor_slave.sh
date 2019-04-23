#!/bin/bash
path="/root/script"
hosts="192.168.157.105, 192.168.157.107"
hostName="PROD-SLAVE, ODS-SLAVE"

IFS=', ' read -r -a hosts <<< "$hosts"
IFS=', ' read -r -a hostName <<< "$hostName"
body=""
nb_up=${#hosts[@]}
for index in "${!hosts[@]}"
do
	body=""
	message=""
	STATUS_LINE=$(mysql --defaults-extra-file=$path/connection.cnf  -h ${hosts[index]}  -e "SHOW SLAVE STATUS\G")"1"
	LAST_ERRNO=$(grep "Last_Errno" <<< "$STATUS_LINE" | awk '{ print $2 }')
	IO_IS_RUNNING=$( grep "Slave_IO_Running" <<< "$STATUS_LINE" | awk '{ print $2 }')
	SQL_IS_RUNNING=$(grep "Slave_SQL_Running" <<< "$STATUS_LINE" | awk '{ print $2; exit }')
	MASTER_LOG_FILE=$(grep " Master_Log_File" <<< "$STATUS_LINE" | awk '{ print $2 }')
	RELAY_MASTER_LOG_FILE=$(grep "Relay_Master_Log_File" <<< "$STATUS_LINE" | awk '{ print $2 }')
	SECONDS_BEHIND_MASTER=$( grep "Seconds_Behind_Master" <<< "$STATUS_LINE" | awk '{ print $2 }')

	## Check For Last Error ##
	if [ "$LAST_ERRNO" != 0 ]
	then
		message="$message \n Error when processing relay log Error : $LAST_ERRNO "
	fi

	## Check if IO thread is running ##
	if [ "$IO_IS_RUNNING" != "Yes" ]
	then
		message="$message \n I/O THREAD IS DOWN"
	fi

	## Check for SQL thread ##
	if [ "$SQL_IS_RUNNING" != "Yes" ]
	then
		message="$message \n SQL THREAD IS DOWN"
	fi

	if [ "$IO_IS_RUNNING" = "Yes" ] && [ "$SQL_IS_RUNNING" = "Yes" ]
	then
		# notiication status and slack emoji
		status="OK"
	        emoji="green_heart"	
		title="[ $status ] ${hostName[index]} Replication Threads up"

		message="$message \n I/O THREAD IS UP"
		message="$message \n SQL THREAD IS UP"
		message="$message \n Run 'SHOW SLAVE STATUS;' for more details. "
	else
		# notiication status and slack emoji
                status="WARNING"
                emoji="heartbeat"
		title="[ $status ] ${hostName[index]} Replication Threads down"

		## Check how slow the slave is ##
        	if [ "$SECONDS_BEHIND_MASTER" == "NULL" ]
	        then
        	       message="$message \n The Slave is reporting 'NULL' seconds behind the master"
	        elif [ "$SECONDS_BEHIND_MASTER" > 60 ]
        	then
	               message="$message \n The Slave is at least 60 seconds behind the master"
        	fi
	        message="$message \n Run 'SHOW SLAVE STATUS;' for more details. "

	fi
	
	body="$body \n $message"

	last_status=$(cat $path/${hostName[index]}_status.log)

	if [ "$last_status" != "$status" ]
	then
	        #echo $title
		#echo $body
		echo -e "$body" | mailx -v -A freeosk -s "$title" mikael.houndegnon@thefreeosk.com
        	bash $path/slack_message.sh -h https://hooks.slack.com/services/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 -c dwbi_db_monitoring -u MySQL-STATUS -i $emoji -m "$body" -T "$title"
	fi

	echo $status > $path/${hostName[index]}_status.log

done
exit 1


