
swapoff -a && swapon -a &
sleep 15
while [ $(free | grep Swap | awk '{print $4}') = "0" ]
do
	sync; echo 1 > /proc/sys/vm/drop_caches
	free -h
done
