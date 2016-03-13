
if ( [ -e srv_image/CentOS-7-x86_64-GenericCloud-1602.raw ] ) then
	echo "Create VDI base image"
  rm srv_image/CentOS-7-x86_64-GenericCloud-1602.vdi
  VBoxManage convertdd srv_image/CentOS-7-x86_64-GenericCloud-1602.raw \
                       srv_image/CentOS-7-x86_64-GenericCloud-1602.vdi \
                       --format VDI \
    && rm srv_image/CentOS-7-x86_64-GenericCloud-1602.raw
fi

echo "Delete old ambari VM"
VBoxManage controlvm "ambari" poweroff
sleep 2
VBoxManage unregistervm "ambari" --delete

echo "Copy new disk image"
rm srv_image/ambari.vdi
VBoxManage clonehd --format VDI \
                   srv_image/CentOS-7-x86_64-GenericCloud-1602.vdi \
                   srv_image/ambari.vdi

echo "Creating new ambari VM"
VBoxManage createvm --name "ambari" --register \
                    --ostype "RedHat_64"

VBoxManage modifyvm "ambari" \
                    --memory 2048 --acpi on \
                    --nic1 intnet --intnet1 clusterLan \
                    --macaddress1 080000000001 \

VBoxManage storagectl "ambari" --name "IDE Controller" --add ide
VBoxManage storageattach "ambari" --storagectl "IDE Controller"  \
                                  --port 0 --device 0 --type hdd \
                     --medium srv_image/ambari.vdi



