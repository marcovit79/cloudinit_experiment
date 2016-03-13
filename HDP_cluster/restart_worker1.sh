echo "Delete old worker1 VM"
VBoxManage controlvm "worker1" poweroff
sleep 2
VBoxManage unregistervm "worker1" --delete

echo "Copy new disk image"
rm srv_image/worker1.vdi
VBoxManage clonehd --format VDI \
                   srv_image/CentOS-7-x86_64-GenericCloud-1602.vdi \
                   srv_image/worker1.vdi 

echo "Creating new worker1 VM"
VBoxManage createvm --name "worker1" --register \
                    --ostype "RedHat_64"

VBoxManage modifyvm "worker1" \
                    --memory 2048 --acpi on \
                    --nic1 intnet --intnet1 clusterLan \
                    --macaddress1 080000000201 \

VBoxManage storagectl "worker1" --name "IDE Controller" --add ide
VBoxManage storageattach "worker1" --storagectl "IDE Controller"  \
                                   --port 0 --device 0 --type hdd \
                     --medium srv_image/worker1.vdi



