# Script folder full path
path="/home/corey/dba/DBA"
# PRODUCTION DB CONFIG
prod_config_file=$path/"prod.cnf"
prod_db="amsdb"

# DEV DB CONFIG
dev_config_file=$path/"dev.cnf"
dev_db="integration_test"
dev_email_suffix="@premiummedia360.com"
ftp_dummy_data="ftp.dev" #this dummy data will be replace in ftp Host, user, password where the table is adsuppliers

echo "########## started table dump from Production($prod_db) to Dev($dev_db) on  $(date)"
echo "########## retrieve list of tables in $prod_db DB "
mysql --defaults-extra-file=$prod_config_file -se"SELECT TABLE_SCHEMA, TABLE_NAME FROM information_schema.tables where TABLE_SCHEMA='$prod_db';" | while read table_list;
do

	list=(${table_list[0]})
	db_name=${list[0]}
	table_name=${list[1]}
	rm -rf $path/$table_name.sql
	echo ""
	echo "***** Table $table_name dump and swap in progress on  $(date) "	
	mysqldump --defaults-extra-file=$prod_config_file $prod_db $table_name  > $path/$table_name.sql
	nb_occurence=$(grep -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b" $path/$table_name.sql | wc -l)
	echo "$nb_occurence occurrence(s) of email found "

	grep -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b" $path/$table_name.sql | while read results;
	do
		# Split results based on @
		email="$(cut -d'@' -f1 <<<"$results")"
		replace_email=$email$dev_email_suffix
		sed -i "s/$results/$replace_email/g" $path/$table_name.sql
	done
	
	echo "copy table $table_name into Dev($dev_db) DB"	
	mysql --defaults-extra-file=$dev_config_file $dev_db < $path/$table_name.sql
	
	# if table is adsuppliers remove ftp configuration
	if [ "$table_name" = "adsuppliers" ] 
	then
		grep -E -o "\bftp+\.[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b" $table_name.sql | while read real_ftp_address;
		do
			echo "replacing ftp parameters for '$real_ftp_address' with '$ftp_dummy_data' from $dev_db.$table_name table"
			mysql --defaults-extra-file=$dev_config_file -e"UPDATE $dev_db.$table_name SET 
									al_post_ftp_address='$ftp_dummy_data', al_post_ftp_username='$ftp_dummy_data', al_post_ftp_password='$ftp_dummy_data',
									ma_ftp_address='$ftp_dummy_data', ma_ftp_username='$ftp_dummy_data', ma_ftp_password='$ftp_dummy_data'
									WHERE al_post_ftp_address='$real_ftp_address';"
		done
	fi
	
	rm -rf $path/$table_name.sql
	echo "***** Table $table_name is now completed on  $(date) "
	echo ""
done

echo "########## table successfully synced $(date)"
