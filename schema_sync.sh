router="192.168.157.152"
# get the list of schema to sync
mysql --defaults-extra-file="/root/script/db.cnf" -h$router -se " SELECT * FROM data_transfer.schema_sync WHERE hidden=0 AND destination_host='192.168.157.152' ;" | while read results;
do {
	row=(${results[0]})
	transfer_id=${row[0]}
	source_host=${row[1]}
	source_schema=${row[2]}
        destination_host=${row[3]}
        destination_schema=${row[4]}
	sync_structure=${row[5]}
	
	
	# for each schema get the list of DB object from Information_schema.tables
	echo "$source_host $source_schema $destination_host $destination_schema $sync_structure"
	
	mysql --defaults-extra-file="/root/script/db.cnf" -h$source_host -se " select TABLE_NAME, TABLE_TYPE from information_schema.tables where TABLE_SCHEMA='$source_schema';" | while read table_list;
	do {
		row_table_list=(${table_list[0]})
		table_name=${row_table_list[0]}
		table_type=${row_table_list[1]}
		is_excluded=0

		# check if the table has a filter defined 
		# a filter can be exclude the table from the transfer list
		# a filter can also be bring last month data only
		
		table_filter_param=$(mysql --defaults-extra-file="/root/script/db.cnf" -h$router -se " select filter_field_name, filter_field_range_start, filter_field_range_end, is_excluded From data_transfer.schema_sync_filter where hidden=0 AND schema_sync_id='$transfer_id' AND db_object_name='$table_name' AND db_object like '$table_type%';")


		if [[ "$table_filter_param" != "" ]]; then
			row_table_filter_param=(${table_filter_param[0]})

	                filter_field_name=${row_table_filter_param[0]}
                	filter_field_range_start=${row_table_filter_param[1]}
        	        filter_field_range_end=${row_table_filter_param[2]}
	                is_excluded=${row_table_filter_param[3]}
			
			 if [[ "$filter_field_name" != "NULL" ]]; then
                		if [[ "$filter_field_range_start" != "NULL" && "$filter_field_range_end" != "NULL" ]]; then
		                        where=" WHERE $filter_field_name BETWEEN '$filter_field_range_start' AND '$filter_field_range_end' "
                		else
		                        if [[ "$filter_field_range_start" != "NULL" ]]; then
                		                where=" WHERE $filter_field_name >= '$filter_field_range_start' "		                    
		                        fi

                		fi
		        fi
		fi
		
				
		if [[ "$is_excluded" = "0" ]]; then
			
			if [[ "$sync_structure" = "1" ]]; then

				sql_file="$table_name.sql"
        	        	mysql --defaults-extra-file="/root/script/db.cnf" -h$destination_host -e "DROP TABLE IF EXISTS $destination_schema.$table_name; "
                		mysqldump --defaults-extra-file="/root/script/db.cnf" --skip-lock-tables --no-data --skip-opt --skip-comments --compact --add-drop-trigger  --triggers --routines -h$source_host $source_schema $table_name > $sql_file
	                	if [[ $table_type != "VIEW"  ]]; then
					sed -i 's/CREATE TABLE/CREATE TABLE IF NOT EXISTS/g' $sql_file
				else
					sed -i 's/CREATE/CREATE OR REPLACE/g' $sql_file
				fi
	        	        mysql --defaults-extra-file="/root/script/db.cnf"  -h$destination_host $destination_schema < $sql_file
				rm -rf $sql_file
			fi
		
			# remove the dump from source and destination before generated new one
			
		        ssh root@$source_host "rm -rf /var/lib/mysql-files/$table_name.txt;"
		        rm -rf /var/lib/mysql-files/$table_name.txt
			
			if [[ $table_type != "VIEW"  ]]; then
				mysql --defaults-extra-file="/root/script/db.cnf" -h$source_host -e"
				SELECT *
				INTO OUTFILE '/var/lib/mysql-files/$table_name.txt'
				FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'
				LINES TERMINATED BY '\n'
				FROM $source_schema.$table_name
				$where"

				scp root@$source_host:/var/lib/mysql-files/$table_name.txt /var/lib/mysql-files/$table_name.txt  </dev/null
				mysql --defaults-extra-file="/root/script/db.cnf" -h$destination_host -e"DELETE FROM $destination_schema.$table_name $where "
				mysql --defaults-extra-file="/root/script/db.cnf" -h$destination_host -e"
				LOAD DATA LOCAL INFILE '/var/lib/mysql-files/$table_name.txt'
				INTO TABLE $destination_schema.$table_name
				FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';"
	
				rm -rf /var/lib/mysql-files/$table_name.txt
			fi
			ssh root@$source_host "rm -rf /var/lib/mysql-files/$table_name.txt;"

		fi
	} < /dev/null; done
} < /dev/null; done
	
