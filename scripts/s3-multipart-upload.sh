#!/usr/bin/env bash

# This script requires: 
# - AWS CLI to be properly configured (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
# - Account has s3:PutObject access for the target S3 bucket

# Usage:
# bash s3-multipart-upload.sh YOUR_FILE YOUR_BUCKET (OPTIONAL: PROFILE)
# bash s3-multipart-upload.sh files.zip my-files
# bash s3-multipart-upload.sh files.zip my-files second-profile

fileName=$1
bucket=$2
profile=${3-default}

#Set to 90 MBs as default, 100 MBs is the limit for AWS files
mbSplitSize=90
((partSize = $mbSplitSize * 1000000))

# Get main file size
echo "Preparing $fileName for multipart upload"
fileSize=`wc -c $fileName | awk '{print $1}'`
((parts = ($fileSize+$partSize-1) / partSize))

# Get main file hash
mainMd5Hash=`openssl md5 -binary $fileName | base64`

# Make directory to store temporary parts
echo "Splitting $fileName into $parts temporary parts"
mkdir temp-parts
cp $fileName temp-parts/
cd temp-parts
split -b $partSize $fileName
rm $fileName

# Create mutlipart upload
echo "Initiating multipart upload for $fileName"
uploadId=`aws s3api create-multipart-upload --bucket $bucket --key $fileName --metadata md5=$mainMd5Hash --profile $profile | jq -r '.UploadId'`

# Generate fileparts.json file that will be used at the end of the multipart upload
jsonData="{\"Parts\":["
for file in *
  do 
    ((index++))		
    echo "Uploading part $index of $parts..."
    hashData=`openssl md5 -binary $file | base64`
    eTag=`aws s3api upload-part --bucket $bucket --key $fileName --part-number $index --body $file --upload-id $uploadId --profile $profile | jq -r '.ETag'`
    jsonData+="{\"ETag\":$eTag,\"PartNumber\":$index}"

    if (( $index == $parts )) 
      then
        jsonData+="]}"
      else
        jsonData+=","
    fi	
done
jq -n $jsonData > fileparts.json

# Complete multipart upload, check ETag to verify success 
mainEtag=`aws s3api complete-multipart-upload --multipart-upload file://fileparts.json --bucket $bucket --key $fileName --upload-id $uploadId --profile $profile | jq -r '.ETag'`
if [[ $mainEtag != "" ]]; 
  then 
    echo "Successfully uploaded: $fileName to S3 bucket: $bucket"
  else
    echo "Something went wrong! $fileName was not uploaded to S3 bucket: $bucket"
fi

# Clean up files
cd ..
rm -R temp-parts
