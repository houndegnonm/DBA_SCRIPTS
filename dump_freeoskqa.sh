user="mhoundegnon"
pwd="PasS123"
rm -rf /var/lib/mysql-files/freeoskqa.sql
mysqldump -u$user -p$pwd --no-create-db --skip-comments --skip-triggers --databases freeoskqa > /var/lib/mysql-files/freeoskqa.sql 

sed -i 's/USE `freeoskqa`/USE `freeoskuat`/g' /var/lib/mysql-files/freeoskqa.sql

mysql -u$user -p$pwd -e"DROP SCHEMA freeoskuat; CREATE SCHEMA freeoskuat;"
mysql -u$user -p$pwd freeoskuat < /var/lib/mysql-files/freeoskqa.sql

mailx -v -A freeosk -s "QA DUMP DONE"  mikael.houndegnon@thefreeosk.com  <<< "Done"
