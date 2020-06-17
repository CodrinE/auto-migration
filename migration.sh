#!/bin/sh

# Usage:
# bash migration.sh

. scripts/lib.sh
. scripts/variables.sh

echo "Checking for aws.."
check_aws

echo "Configuring aws...."
init_aws $KEY_ID $SECRET_KEY $REGION

#Convert image file
echo "Converting file...."
CONVERTED_FILE=$(convert_vm $INPUT_FILE $OUTPUT_FORMAT)

#Check if bucket exists
echo "Checking for $S3_BUCKET..."
check_for_bucket $S3_BUCKET $REGION

#Uploading file in parts
echo "Please wait! Uploading file...."
upload_file $CONVERTED_FILE $S3_BUCKET

echo "Cleaning up..."
#rm -r temp-parts
#check or create key pair
echo "Checking for key pair"
check_key_pair $KEY_PAIR

#check or create security group + get groupId
echo "Checking for security group"
GROUP_ID=$(check_security_group $GROUP_NAME)

#add ingress and egress rules to group
echo "Adding ingress rules for http, https and ssh"
add_ingress_rules $GROUP_NAME
echo "Adding Egress rules for http, https"
add_egress_rules $GROUP_ID

#Create aws EC2 instance
echo "Creating EC2 instance using imageId $IMAGE_ID"
INSTANCE_ID=$(create_ec2_instance $IMAGE_ID $COUNT $INSTANCE_TYPE $KEY_PAIR $GROUP_ID $REGION)

#Check if instance is running
while [ $(instance_check $INSTANCE_ID) != "running" ];do
    echo "Instance not running yet, waiting 30sec..."
    sleep 10
done


PUBLIC_DNS=$(get_instance_public_dns $INSTANCE_ID)
echo "Public DNS is: $PUBLIC_DNS"

chmod +x scripts/lib.sh
chmod +x scripts/vm-scripts/vm-lib.sh
chmod +x scripts/vm-scripts/build.sh

 ssh -i "keys/awslinux.pem" ec2-user@$PUBLIC_DNS "sudo rm -r ~/scripts"
 scp -i "keys/awslinux.pem" -r scripts/  ec2-user@$PUBLIC_DNS:~/scripts
 ssh -i "keys/awslinux.pem" ec2-user@$PUBLIC_DNS \
    "cd ~/scripts/vm-scripts && sudo bash ~/scripts/vm-scripts/build.sh \
        $KEY_ID $SECRET_KEY $REGION $S3_BUCKET '${CONVERTED_FILE##*/}'"
