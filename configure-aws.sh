#!/bin/bash

# Usage:
# bash configure-aws.sh

key_id=$(jq '.AccessKey' conf/aws-configuration.json)
secret_access_key=$(jq '.SecretAccessKey' conf/aws-configuration.json)
region=$(jq '.Region' conf/aws-configuration.json)

aws configure set aws_access_key_id ${key_id}
aws configure set aws_secret_access_key ${secret_access_key}
aws configure set region ${region}

#Display configuration
aws configure list