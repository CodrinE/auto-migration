#!/usr/bin/env bash
. ../lib.sh

install_dependencies() {
    sudo yum install qemu-kvm qemu-img virt-manager libvirt  libvirt-client \
        virt-install virt-viewer libguestfs-tools jq zip -y
    check_aws
}

init_services() {
    sudo systemctl start libvirtd
    sudo systemctl enable libvirtd
}

download_s3_file() {
# BUCKET=$1  FILE_NAME=$2
    mkdir -p /home/ec2-user/image/
    sudo chown ec2-user:ec2-user /home/ec2-user/image/
    cd  /home/ec2-user/image/
    aws s3 cp s3://$1/$2 $2
}

init_storage_pool() {
# POOL_NAME=$1
    sudo virsh pool-define-as $1 dir - - - - "/$1"
    sudo virsh pool-build $1
    sudo virsh pool-start $1
    sudo virsh pool-autostart $1
}

create_img_volume() {
# FILE_NAME=$1 POOL_NAME=$2 VOLUME_NAME=$3
    sudo chown root:root $1
    sudo virsh vol-create-as $2 $3 $(qemu-img info --output json $1 | jq -r .[\"virtual-size\"]) --format qcow2
    sudo virsh vol-upload --pool $2 --vol $3 $1
}
install_vm() {
#VM_NAME=$1 RAM=$2 POOL_NAME=$3 VOLUME_NAME=$4  OUTPUT_FORMAT=$5
    sudo virt-install --name $1 --os-variant alpinelinux3.7 --memory $2 \
    --disk pool=$3,size=1,backing_store=$(sudo virsh vol-path --pool $3 \
    --vol $4),backing_format=$5   --import --graphics vnc \
    --network default,model=virtio --noautoconsole
}