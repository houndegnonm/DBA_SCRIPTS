#!/bin/bash
path="/root/script"
hosts="192.168.157.101, 192.168.157.102, 192.168.157.103, 192.168.157.104, 192.168.157.105, 192.168.157.106, 192.168.157.107, 192.168.157.176"
hostName="DEV, QA, UAT, PROD-MASTER, PROD-SLAVE, ODS-MASTER, ODS-SLAVE, PII"
#hosts="192.168.157.102"
#hostName="QA"


IFS=', ' read -r -a hosts <<< "$hosts"
IFS=', ' read -r -a hostName <<< "$hostName"
body=""
emoji="heartbeat"
nb_up=${#hosts[@]}

echo "####################### Start # Of connection check at  $( date '+%Y-%m-%d %H:%M:%S' )"
for index in "${!hosts[@]}"
do
	nb_connection=$(mysql --defaults-extra-file=$path/connection.cnf -h ${hosts[index]} -se"select count(*) from information_schema.processlist")
	echo "$index ${hosts[index]} ${hostName[index]} : $nb_connection"	
	if [ $nb_connection -gt 420 ]	
	then
		title="Warning : $nb_connection  Connections on ${hostName[index]} DB"
		#check how many connection from webport
		nb_webport_connection=$(mysql --defaults-extra-file=$path/connection.cnf -h ${hosts[index]} -se"select count(*) from information_schema.processlist 
					WHERE SUBSTRING(host,1,15) in ('192.168.157.126','192.168.157.130','192.168.157.131','192.168.157.133') ")

		# Kill half of connection comming from webport
		nb_to_kill=$((nb_webport_connection/2))
		
		body="${hostName[index]} DB reached $nb_connection Connections. $nb_to_kill Connections from  Webport will be automatically killed, please review ASAP."
                mailx -v -A freeosk -s $title  mikael.houndegnon@thefreeosk.com viral.mehta@thefreeosk.com  <<< $body
                bash $path/slack_message.sh -h https://hooks.slack.com/services/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 -c dwbi_db_monitoring -u MySQL-STATUS -i $emoji -m "$body" -T "$title"
		
		#join to this list all sleeping connection from other user@host
	
		mysql --defaults-extra-file=$path/connection.cnf -h ${hosts[index]} -se"select ID from information_schema.processlist WHERE COMMAND='Sleep' AND TIME > 30000 UNION ALL ( SELECT ID FROM information_schema.processlist WHERE SUBSTRING(host,1,15) in ('192.168.157.126','192.168.157.130','192.168.157.131','192.168.157.133') order by TIME DESC LIMIT $nb_to_kill ) " | while read ID; do
        		mysql --defaults-extra-file=$path/connection.cnf -h ${hosts[index]}  -e"KILL $ID"
		done
	fi
done
echo "####################### End Of # connection check at  $( date '+%Y-%m-%d %H:%M:%S' )"
