#! /bin/bash

echo "Add second network interface"
cp /vagrant/metaserver_files/metaserver-eth1.cfg /etc/network/interfaces.d/eth1.cfg
ifup eth1


echo "Update packages list and update installed packages"
apt-get -y -q update
apt-get -y -q upgrade


echo "Install DHCP Serve with DNS proxy capability ..."
cp /vagrant/metaserver_files/add_to_hosts.sh /etc/add_to_hosts.sh
chmod u+x /etc/add_to_hosts.sh
echo "" >> /etc/hosts
echo "" >> /etc/hosts
echo "# Dhcp client list " >> /etc/hosts

apt-get -y -q install dnsmasq
cp /vagrant/metaserver_files/metaserver-dnsmasq.conf /etc/dnsmasq.conf
service dnsmasq restart
echo "    ... add gateway capability"
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/80-ipv4_forward.conf
iptable_rule="iptables -t nat -A POSTROUTING -s 169.254.169.0/24 -o eth0 -j MASQUERADE"
sed -i -e "|exit 0|$iptable_rule\nexit 0|" /etc/rc.local 
$iptable_rule


echo "Generate key for virtual machines access"
mkdir -p /vagrant/keys/
if ( [ ! -e /vagrant/keys/ambari_user.key ] ) then 
  ssh-keygen -f /vagrant/keys/ambari_user.key -N ""
fi

echo "Install web server"
apt-get -y -q install nginx

sleep 2

echo "change web documents root"
cp /vagrant/metaserver_files/nginx-metadata-server /etc/nginx/sites-available/default
echo "Enable Public Key value substitution"
sed -i -e "s|PK_VALUE_XYZ|$( cat /vagrant/keys/ambari_user.key.pub)|" \
                                                    /etc/nginx/sites-available/default
echo "Disable sendfile due to vboxfs limitation"
sed -i -e 's|^\t*sendfile on;|    sendfile off;|' /etc/nginx/nginx.conf 
sleep 2

echo "Restart web server"
service nginx stop
service nginx start



echo "Install utilities to connect to ambari"
apt-get -y -q install xauth firefox



echo "Install tools for modify servers image"
apt-get -y -q install qemu libguestfs-tools
update-guestfs-appliance
chmod +r /boot/vmlinuz-3.13.0-79-generic

echo "Download servers image"
mkdir -p /vagrant/srv_image
cd /vagrant/srv_image
if ( [ ! -e CentOS-7-x86_64-GenericCloud-1602.raw.tar.gz ] ) then
  wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1602.raw.tar.gz
fi
tar xvf CentOS-7-x86_64-GenericCloud-1602.raw.tar.gz


echo "Config the image"
guestfish -a CentOS-7-x86_64-GenericCloud-1602.raw <</EOF
  set-selinux true
  run
  mount /dev/sda1 /
  sh "adduser -G wheel backdoor"
  sh "echo backdoor | passwd --stdin backdoor"
  sh "sed -i -e 's/DEVICE=\"eth0\"/DEVICE=\"enp0s3\"/' /etc/sysconfig/network-scripts/ifcfg-eth0"

  sh "chcon system_u:object_r:passwd_file_t:s0 /etc/passwd"
  sh "chcon system_u:object_r:passwd_file_t:s0 /etc/group"
  sh "chcon system_u:object_r:shadow_t:s0 /etc/shadow"
  sh "chcon system_u:object_r:net_conf_t:s0 /etc/sysconfig/network-scripts/ifcfg-eth0"
  umount /
/EOF

