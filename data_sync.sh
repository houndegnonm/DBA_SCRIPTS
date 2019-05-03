user="mhoundegnon"
pwd="PasS123"

mysql -u$user -p$pwd -se " SELECT * FROM data_transfer.table_config WHERE hidden=0 ;" | while read results; 
do
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
	
	if [[ "$filter_field_name" != "NULL" ]]; then
		if [[ "$filter_field_range_start" != "NULL" && "$filter_field_range_end" != "NULL" ]]; then
			where=" $filter_field_name BETWEEN '$filter_field_range_start' AND '$filter_field_range_end' "
		else 
			if [[ "$filter_field_range_start" != "NULL" ]]; then
				where=" $filter_field_name >= $filter_field_range_start "
			else
				echo "You must specified in table data_transfer.table_config either start field only or both start and end field"
			fi

		fi
	fi
	
	if [[ "sync_structure" == "1" ]]; then
		sql_file="$table_name.sql"
		mysql -u$user -p$pwd -h$destination_host -e "DROP TABLE IF EXISTS $destination_schema.$table_name; "
		mysqldump --skip-lock-tables --no-data --skip-opt --skip-comments --compact  -u$user -p$pwd -h$source_host $source_schema $table_name > $sql_file
		sed -i 's/CREATE TABLE/CREATE TABLE IF NOT EXISTS/g' $sql_file
		mysql -u$user -p$pwd -h$destination_host $destination_schema < $sql_file
	fi
	
	if [[ "$where" != "" ]]; then
		pt-table-sync --where "$where" --execute h=$source_host,u=$user,p=$pwd,D=$source_schema,t=$table_name h=$destination_host,u=$user,p=$pwd,D=$destination_schema,t=$table_name
	else
		pt-table-sync --execute h="$source_host",u="$user",p="$pwd",D="$source_schema",t="$table_name" h="$destination_host",u="$user",p="$pwd",D="$destination_schema",t="$table_name"
	fi
	
	exit
done

