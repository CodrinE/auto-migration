#!/usr/bin/env bash


KEY_ID=$1
SECRET_KEY=$2
REGION=$3
BUCKET=$4
INPUT_FILE="${5##*/}"
INPUT_FORMAT="${INPUT_FILE#*.}"
OUTPUT_FORMAT="qcow2"
POOL_NAME="default"
VOLUME_NAME="alpine-virt"
VM_NAME="alpine-vm"
RAM=400 #In mb
