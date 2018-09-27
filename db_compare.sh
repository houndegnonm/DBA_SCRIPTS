
mysql -u"mysqldbuser@pm360-production" -p"4geD1yXoe2fS5obpp34G" -h"pm360-production.mysql.database.azure.com" -se"SELECT TABLE_SCHEMA, TABLE_NAME FROM information_schema.tables where TABLE_SCHEMA='amsdb';" | while read results;
do
        row=(${results[0]})
	db_name=${row[0]}
	table_name=${row[1]}
	echo "$table_name "
	mysqldump --skip-add-locks --no-create-info --skip-comments --skip-opt  --compact --skip-extended-insert -u"mysqldbuser@pm360-production" -p"4geD1yXoe2fS5obpp34G" -h"pm360-production.mysql.database.azure.com"  $db_name $table_name > $table_name"1".sql

	mysqldump --skip-add-locks --no-create-info --skip-comments --skip-opt  --compact --skip-extended-insert -u"mysqldbuser@production-monday13" -p"4geD1yXoe2fS5obpp34G" -h"production-monday13.mysql.database.azure.com" $db_name $table_name > $table_name"2".sql

	diff $table_name"1".sql $table_name"2".sql >> "table_diff.sql"
	#exit 1
done
