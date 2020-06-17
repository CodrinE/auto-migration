#!/usr/bin/env bash
set -x
. ./variables.sh
. ./vm-lib.sh


#Install necessary packages
echo "Installing necessary packages.."
install_dependencies

echo "Configuring aws...."
init_aws $KEY_ID $SECRET_KEY $REGION

echo "Starting required services.."
init_services

echo "Downloading image.."
download_s3_file $BUCKET  $INPUT_FILE

echo "Creating storage pool.."
init_storage_pool $POOL_NAME

echo "Converting to allowed format..."
CONVERTED_FILE=$(convert_vm  /home/ec2-user/image/$INPUT_FILE  $OUTPUT_FORMAT)


echo " Creating volume..."
create_img_volume $CONVERTED_FILE $POOL_NAME $VOLUME_NAME

echo "Installing vm..."
install_vm $VM_NAME $RAM $POOL_NAME $VOLUME_NAME  $OUTPUT_FORMAT

echo "Starting image..."
sudo virsh start alpine-vm
sudo virsh autostart alpine-vm
