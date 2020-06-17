#!/usr/bin/env bash
set -x
check_aws() {
 if aws --version 2>&1 | grep 'aws-cli'
 then
     echo "aws already installed! proceeding..."
 else
     echo "aws not found..."
     echo "Installing...."
     curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
     unzip awscliv2.zip
     sudo ./aws/install
     rm awscliv2.zip
  fi
}

init_aws()  { #Set initial aws account details
# KEY_ID=$1    SECRET_KEY=$2   REGION=$3
    aws configure set aws_access_key_id $1
    aws configure set aws_secret_access_key $2
    aws configure set region $3
    aws configure list  #Display configuration
}

check_for_bucket() {  #Create S3 Bucket if doesn't exist
# BUCKET=$1    REGION=$2
    if aws s3 ls "s3://$1" 2>&1 | grep -q 'NoSuchBucket'
    then
        echo "Creating s3 bucket $1"
        aws s3 mb s3://$1 --region $2
    fi
}

check_key_pair(){
# KEY_PAIR_NAME=$1
    if aws ec2 describe-key-pairs --key-names $1 2>&1 | grep -q 'InvalidKeyPair'
    then
      echo "Creating key pair $1"
      mkdir -p keys
#      echo $(aws ec2 create-key-pair --key-name $1 | jq '.KeyMaterial') > keys/$1.pem
      echo $(aws ec2 create-key-pair --key-name $1 | jq '.KeyMaterial') | tail -c +2 | head -c -2 > keys/$1.pem
      chmod 400 keys/$1.pem
     else
        echo "Key Pair exists already."
    fi
}

check_security_group() {
# GROUP_NAME=$1
    if aws ec2 describe-security-groups --group-names $1 2>&1 | grep -q 'InvalidGroup'
    then
        echo $(aws ec2 create-security-group \
            --group-name $1 \
            --description 'This security group is for web servers' | jq -r '.SecurityGroups[] | .GroupId')
     else
        echo $(aws ec2 describe-security-groups --group-names $1 | jq -r '.SecurityGroups[] | .GroupId')
    fi
}
add_ingress_rules() {
# GROUP_NAME=$1
    aws ec2 authorize-security-group-ingress --group-name $1 \
        --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null 2>&1
    aws ec2 authorize-security-group-ingress --group-name $1 \
        --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null 2>&1
    aws ec2 authorize-security-group-ingress --group-name $1 \
        --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null 2>&1
}

add_egress_rules() {
# GROUP_ID=$1
    aws ec2 revoke-security-group-egress --group-id $1 --protocol all --port all --cidr 0.0.0.0/0 > /dev/null 2>&1
    aws ec2 authorize-security-group-egress --group-id $1 --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null 2>&1
    aws ec2 authorize-security-group-egress --group-id $1 --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null 2>&1
}

create_ec2_instance() {
#   IMAGE_ID=$1 COUNT=$2 TYPE=$3 KEY_NAME=$4 GROUP_ID=$5 REGION=$6
    aws ec2 run-instances --image-id $1 \
        --count $2  --instance-type $3 \
        --key-name $4 \
        --security-group-ids $5 \
        --associate-public-ip-address \
        --region $6 | jq -r '.Instances[] | .InstanceId'
}

instance_check() { # check if instance is in running state
# INSTANCE_ID=$1
   echo $(aws ec2 describe-instances --instance-id $1 | jq -r '.Reservations[] | .Instances[] | .State | .Name')
}

get_instance_public_dns() { #Query for public dns
# INSTANCE_ID=$1
    echo $(aws ec2 describe-instances \
    --instance-id $1 \
    | jq -r '.Reservations[] | .Instances[] | .NetworkInterfaces[] | .PrivateIpAddresses[] | .Association.PublicDnsName')
}

upload_file_parts() {     #Upload file to s3 bucket
#    INPUT_FILE=$1    BUCKET=$2
    if [ -d "temp-parts" ]; then rm -Rf temp-parts; fi
    chmod -x scripts/s3-multipart-upload.sh
    bash scripts/s3-multipart-upload.sh $1 $2
}

convert_vm() { #Convert vm image file to other format
# $FILE_NAME=$1    OUTPUT_FORMAT=$2
    FILE_NAME="${1##*/}"  #Extract input_file
    FILE_EXTENSION=$(qemu-img info $1 | grep "file format")
    FILE_EXTENSION=$(echo "${FILE_EXTENSION##*:}" | xargs)  #Get current format
    FILE="${FILE_NAME%.*}"   #Get file name
    FILE_PATH=$(readlink -f $1 | sed "s!\(.*\)/.*!\1!")  #Get absolute path

    #Converting vm
    qemu-img convert -f ${FILE_EXTENSION} $1 -O $2 ${FILE_PATH}/${FILE}.$2
    echo "${FILE_PATH}/${FILE}.$2"
}


