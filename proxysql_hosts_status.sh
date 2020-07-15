#!/bin/bash

repeat_alert_interval=5 # minutes
lock_file=/tmp/proxysql_status_alert.lck
active=yes
pager_duty_email="pager dutty email integration here "

### send notification to pager duty. 
function give_it_up_to_pager_duty () {
#        echo "am in pager duty"
        echo "$2 " | mail -s "`hostname` - ProxySQL Status issue $1" "$pager_duty_email"
        echo "sent email to pager duty with subject : $1 and error:  $2"
}


## Check if alert is already sent ##
function check_alert_lock () {
    if [ -f $lock_file ] ; then
        current_file=`find $lock_file -cmin -$repeat_alert_interval`
        if [ -n "$current_file" ] ; then
            # echo "Current lock file found"
            return 1
        else
            # echo "Expired lock file found"
            return 2
        fi
    else
    return 0
    fi
}

shunned_host=$(mysql --login-path=proxysql -se "select hostname  from runtime_mysql_servers WHERE status='SHUNNED' group by 1")
online_host=$(mysql  --login-path=proxysql -se "select hostname  from runtime_mysql_servers WHERE status='ONLINE' group by 1")

if [ "$online_host" != "" ]; then
        if [ "$shunned_host" != "" ]; then
                check_alert_lock
                if [ $? = 1 ] ; then
                        ## Current Lock ##
                        echo "up" > /dev/null
                        echo "WARNING SENT LESS THAN $repeat_alert_interval minutes" > /dev/null
                else
                        ## Stale/No Lock ##
                        touch $lock_file
                        errsubj=" Proxysql Failover from $shunned_host to $online_host "
                        errtext=" $shunned_host , currently marked as 'SHUNNED', existing connections will be killed and new Connection will be redirected to $online_host. Please Review"
                        give_it_up_to_pager_duty  "$errsubj"  "$errtext"
                fi
        else
                if [ -f $lock_file ] ; then
                        rm $lock_file
                        errsubj="Proxysql Failover from $shunned_host to $online_host "
                        errtext="All hosts are now ONLINE in ProxySQL"
                        echo "All hosts are now ONLINE in ProxySQL" > /dev/null
                        echo "Removed Alert Lock" > /dev/null
                else
                        echo "Yay! all defined hosts are ONLINE in ProxySQL" > /dev/null
                fi
                exit 0
        fi
else
        check_alert_lock
        if [ $? = 1 ] ; then
                ## Current Lock ##
                echo "up" > /dev/null
                echo "WARNING SENT LESS THAN $repeat_alert_interval minutes" > /dev/null
        else
                ## Stale/No Lock ##
                touch $lock_file
                errsubj="Proxysql Failover ERROR "
                errtext="ProxySQL has 0 host marked 'ONLINE'. Please Review"
                give_it_up_to_pager_duty  "$errsubj"  "$errtext"
        fi
fi
