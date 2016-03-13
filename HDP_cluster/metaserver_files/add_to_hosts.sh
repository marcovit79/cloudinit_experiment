#! /bin/bash 

action=$1
mac=$2
ip=$3
name=$4


echo "$action $mac $ip $name" >> /var/log/dhcp_registration.log

if ( [ "x$name" != "xlocalhost"  -a  "x$name" != "x" ] ) then
	
	echo "$action" >> /var/log/dhcp_registration.log
	sed -i -e "/.* $name$/ { d }" /etc/hosts
	sed -i -e "/^$ip .*/ { d }" /etc/hosts

	if ( [  "x$action" = "xadd"  -o  "x$action" = "xold"  ] ) then
		echo "$ip $name" >> /etc/hosts
	fi
fi

echo "end" >> /var/log/dhcp_registration.log


