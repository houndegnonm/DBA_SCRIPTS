user="mhoundegnon"
pwd="PasS123"
qa_router_host="192.168.157.152"
path="/root/script"

mysql --defaults-extra-file="$path/connection.cnf" -h$qa_router_host -se " SELECT * FROM data_transfer.table_config WHERE hidden=0 ;" | while read results; 
do
	echo  " *** $source_schema.$table_name "
	row=(${results[0]})
        table_name=${row[1]}
	filter_field_name=${row[2]}
	filter_field_range_start=${row[3]}
	filter_field_range_end=${row[4]}
	source_host=${row[5]}
	source_schema=${row[6]}
	destination_host=${row[7]}
	destination_schema=${row[8]}
	sync_structure=${row[9]}

	# echo "table_name $table_name, filter_field_name $filter_field_name, filter_field_range_start $filter_field_range_start, filter_field_range_end $filter_field_range_end, source_host $source_host, source_schema $source_schema, destination_host $destination_host, destination_schema $destination_schema, sync_structure $sync_structure" 	
	# exit
	if [[ "$filter_field_name" != "NULL" ]]; then
		if [[ "$filter_field_range_start" != "NULL" && "$filter_field_range_end" != "NULL" ]]; then
			where=" WHERE $filter_field_name BETWEEN '$filter_field_range_start' AND '$filter_field_range_end' "
		else 
			if [[ "$filter_field_range_start" != "NULL" ]]; then
				where=" WHERE $filter_field_name >= $filter_field_range_start "
			else
				echo "You must specified in table data_transfer.table_config either start field only or both start and end field"
				exit
			fi

		fi
	fi
	
	# sync structure here
	if [[ "$sync_structure" == "1" ]]; then
		echo  " *** Structure Change"
		sql_file="$table_name.sql"
		mysql --defaults-extra-file="$path/connection.cnf" -h$destination_host -e "DROP TABLE IF EXISTS $destination_schema.$table_name; "
		mysqldump --defaults-extra-file="$path/connection.cnf"  --skip-lock-tables --no-data --skip-opt --skip-comments --compact --add-drop-trigger  --triggers -h$source_host $source_schema $table_name > $sql_file
		sed -i 's/CREATE TABLE/CREATE TABLE IF NOT EXISTS/g' $sql_file
		mysql --defaults-extra-file="$path/connection.cnf"  -h$destination_host $destination_schema < $sql_file
	fi
	
	# remove the dump from source and destination before generated new one
	echo  " *** Cleanup old dump "
	ssh root@$source_host "rm -rf /var/lib/mysql-files/$table_name.txt;"
	rm -rf /var/lib/mysql-files/$table_name.txt
	
	# generate and stream the dump from source to destination
	# echo $where 
	# exit 1
	if [[ "$where" != "" ]]; then
		echo  " *** Generate dump on source DB Server "
	 	mysql --defaults-extra-file="$path/connection.cnf" -h$source_host -e"
                        SELECT *
                                INTO OUTFILE '/var/lib/mysql-files/$table_name.txt'
                        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'
                        LINES TERMINATED BY '\n'
                        FROM $source_schema.$table_name
                        $where
		"	
		echo  " *** Copy dump to destination "
		scp root@$source_host:/var/lib/mysql-files/$table_name.txt /var/lib/mysql-files/$table_name.txt
		
		echo  " *** Load dump into destination"
		mysql --defaults-extra-file="$path/connection.cnf"  -h$destination_host -e"
                        LOAD DATA INFILE '/var/lib/mysql-files/$table_name.txt'
		        INTO TABLE $destination_schema.$table_name
		        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';
                "
		# pt-table-sync --where "$where" --nocheck-triggers --execute h=$source_host,u=$user,p=$pwd,D=$source_schema,t=$table_name h=$destination_host,u=$user,p=$pwd,D=$destination_schema,t=$table_name
	else
		echo  " *** Generate dump on source DB Server "
		mysql --defaults-extra-file="$path/connection.cnf"  -h$source_host -e"
			SELECT *
			        INTO OUTFILE '/var/lib/mysql-files/$table_name.txt'
			FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'
			LINES TERMINATED BY '\n'
		        FROM $source_schema.$table_name
		"

		echo  " *** Copy dump to destination "
		scp root@$source_host:/var/lib/mysql-files/$table_name.txt /var/lib/mysql-files/$table_name.txt
		
		echo  " *** Load dump into destination"
                mysql --defaults-extra-file="$path/connection.cnf" -h$destination_host -e"
                        LOAD DATA INFILE '/var/lib/mysql-files/$table_name.txt'
                        INTO TABLE $destination_schema.$table_name
                        FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';
		"
		
		# pt-table-sync --nocheck-triggers --execute h="$source_host",u="$user",p="$pwd",D="$source_schema",t="$table_name" h="$destination_host",u="$user",p="$pwd",D="$destination_schema",t="$table_name"
	fi
	

done

