echo "Delete old master1 VM"
VBoxManage controlvm "master1" poweroff
sleep 2
VBoxManage unregistervm "master1" --delete

echo "Copy new disk image"
rm srv_image/master1.vdi
VBoxManage clonehd --format VDI \
                   srv_image/CentOS-7-x86_64-GenericCloud-1602.vdi \
                   srv_image/master1.vdi 

echo "Creating new master1 VM"
VBoxManage createvm --name "master1" --register \
                    --ostype "RedHat_64"

VBoxManage modifyvm "master1" \
                    --memory 2048 --acpi on \
                    --nic1 intnet --intnet1 clusterLan \
                    --macaddress1 080000000101 \

VBoxManage storagectl "master1" --name "IDE Controller" --add ide
VBoxManage storageattach "master1" --storagectl "IDE Controller"  \
                                   --port 0 --device 0 --type hdd \
                     --medium srv_image/master1.vdi



