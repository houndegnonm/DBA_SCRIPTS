usage() {
        echo "usage: ./$(basename $0) [qa or prod or edw or ods]"
}

if [ $# -eq 0 ]
then
        usage
        exit 1
fi

case $1 in
        "prod")
                slave_ip_address="192.168.157.105"
        ;;
        "ods")
                slave_ip_address="192.168.157.107"
        ;;
*) echo "invalid option";;
esac

mysql -u mhoundegnon -p"PasS123"  -e "SHOW Master status \G" | ssh root@$slave_ip_address " cat - > /root/script/master.info "
ssh root@$slave_ip_address "rm -rf /var/db_backups/full/*"
mysql -u mhoundegnon -p"PasS123" -e "GRANT ALL PRIVILEGES ON *.* TO 'slave_user'@'%' IDENTIFIED BY 'DV17Nol@nn' WITH GRANT OPTION; FLUSH PRIVILEGES; "
sudo innobackupex --user=mhoundegnon --password=PasS123 --no-lock --history --stream=xbstream ./ | ssh root@$slave_ip_address "xbstream -x -C /var/db_backups/full/"
ssh root@$slave_ip_address "sudo innobackupex --apply-log --redo-only /var/db_backups/full"
mailx -v -A freeosk -s "$1 Slave DB migration Step 1 is complete "  mikael.houndegnon@thefreeosk.com  db_support@thefreeosk.com <<< "$1 master DB is ready, the next step is to setup the new $1 slave"