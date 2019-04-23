#!/bin/bash
path="/root/script"
hosts="192.168.157.101, 192.168.157.102, 192.168.157.103, 192.168.157.104, 192.168.157.105, 192.168.157.106, 192.168.157.107, 192.168.157.176"
hostName="DEV, QA, UAT, PROD-MASTER, PROD-SLAVE, ODS-MASTER, ODS-SLAVE, PII"

IFS=', ' read -r -a hosts <<< "$hosts"
IFS=', ' read -r -a hostName <<< "$hostName"
body=""
nb_up=${#hosts[@]}
for index in "${!hosts[@]}"
do
	# echo "$index ${hosts[index]} ${hostName[index]}"
	status_check=$(mysql --defaults-extra-file=$path/connection.cnf  -h ${hosts[index]}  -se"select @@version;")
	if [ "$status_check" = "5.7.23-log" ] || [ "$status_check" = "5.7.24-log" ] 
	then
		uptime=$(mysqladmin --defaults-extra-file=$path/connection.cnf  -h ${hosts[index]}  version | grep -i uptime)
		uptime=${uptime:10:100}
		message=" - ${hostName[index]} DB is UP, Uptime: $uptime"
		echo "$index ${hosts[index]} ${hostName[index]} DB is UP, Uptime: $uptime"
	else
		message=" - ${hostName[index]} DB is DOWN, or the DB Version is not 5.7.23"
		echo "$index ${hosts[index]} ${hostName[index]} DB is DOWN, or the DB Version is not 5.7.23"
		((nb_up--))
	fi
	body="$body \n $message"
done
if [ "$nb_up" = "${#hosts[@]}" ]
then
	status="OK"
	emoji="green_heart"
else
	status="WARNING"
	emoji="heartbeat"
fi
last_status=$(cat $path/db_status.log)

if [ "$last_status" != "$status" ]
then
	title="[ $status ] $nb_up/${#hosts[@]} MySQL DB Services are UP and Running"
	echo -e "$body" | mailx -v -A freeosk -s "[ $status ] $nb_up/${#hosts[@]} MySQL DB Services are UP and Running " mikael.houndegnon@thefreeosk.com
	bash $path/slack_message.sh -h https://hooks.slack.com/services/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 -c dwbi_db_monitoring -u MySQL-STATUS -i $emoji -m "$body" -T "$title"
fi

echo $status > $path/db_status.log
exit 1


