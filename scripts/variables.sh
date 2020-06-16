#!/usr/bin/env bash

CONFIG_FILE='conf/aws-configuration.json'
KEY_ID=$(jq -r '.AwsSetup | .AccessKey' ${CONFIG_FILE})
SECRET_KEY=$(jq -r '.AwsSetup | .SecretAccessKey' ${CONFIG_FILE})
REGION=$(jq -r '.AwsSetup | .Region' ${CONFIG_FILE})
INPUT_FILE=$(jq -r '.ConvertDetails | .InputFile' ${CONFIG_FILE})
OUTPUT_FORMAT=$(jq -r '.ConvertDetails | .OutputFormat' ${CONFIG_FILE})
S3_BUCKET=$(jq -r '.AwsSetup | .S3 | .Bucket' ${CONFIG_FILE})
KEY_PAIR=$(jq -r '.AwsSetup | .KeyPairs | .KeyPairName' ${CONFIG_FILE})
GROUP_NAME=$(jq -r '.AwsSetup | .SecurityGroup | .GroupName' ${CONFIG_FILE})
IMAGE_ID=$(jq -r '.AwsInstanceSpecs | .ImageId' ${CONFIG_FILE})
COUNT=$(jq -r '.AwsInstanceSpecs | .NumberOfInstances' ${CONFIG_FILE})
INSTANCE_TYPE=$(jq -r '.AwsInstanceSpecs | .InstanceType' ${CONFIG_FILE})
