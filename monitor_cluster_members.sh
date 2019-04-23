#!/bin/bash
path="/root/script"
hosts="192.168.157.152"
hostName="QA-CLUSTER"
total_node=3
IFS=', ' read -r -a hosts <<< "$hosts"
IFS=', ' read -r -a hostName <<< "$hostName"
body=""
nb_up=${#hosts[@]}
for index in "${!hosts[@]}"
do
	body=""
	message=""
	nb_node=$(mysql --defaults-extra-file=$path/connection.cnf  -h ${hosts[index]}  -se "SELECT count(*) from performance_schema.replication_group_members WHERE MEMBER_STATE='ONLINE';")
	
	if [ $nb_node -lt $total_node ]
	then
		nb_node_left=$(($total_node-nb_node))
		# notiication status and slack emoji
                status="WARNING"
                emoji="heartbeat"
                title="[ $status ] ${hostName[index]}"
		message="$nb_node_left/$total_node Member(s) left the Cluster.\n $nb_node/$total_node Member(s) remain online : "
		list=$(mysql --defaults-extra-file=$path/connection.cnf  -h ${hosts[index]}  -se "SELECT group_concat(MEMBER_HOST) from performance_schema.replication_group_members WHERE MEMBER_STATE='ONLINE' ;")
		message="$message $list"
	else
		# notiication status and slack emoji
                status="OK"
                emoji="green_heart"
                title="[ $status ] ${hostName[index]}"
		list=$(mysql --defaults-extra-file=$path/connection.cnf  -h ${hosts[index]}  -se "SELECT group_concat(MEMBER_HOST) from performance_schema.replication_group_members WHERE MEMBER_STATE='ONLINE';")
                message="$nb_node/$total_node Members are online : $list "
	fi

	body="$body \n $message"
	last_status=$(cat $path/${hostName[index]}_node_status.log)

	if [ "$last_status" != "$status" ]
	then
	        #echo $title
		#echo $body
		echo -e "$body" | mailx -v -A freeosk -s "$title" mikael.houndegnon@thefreeosk.com
        	bash $path/slack_message.sh -h https://hooks.slack.com/services/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 -c dwbi_db_monitoring -u MySQL-STATUS -i $emoji -m "$body" -T "$title"
	fi

	echo $status > $path/${hostName[index]}_node_status.log

done
exit 1


