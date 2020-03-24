#!/bin/bash
#echo "************* execute terraform init"
## execute terrafotm build and sendout to packer-build-output

#terraform plan 

ls -la
echo "************* execute terraform plan -var manageddiskname=$6"

## execute terrafotm build and sendout to packer-build-output
export ARM_CLIENT_ID=$1
export ARM_CLIENT_SECRET=$2
export ARM_SUBSCRIPTION_ID=$3
export ARM_TENANT_ID=$4
export ARM_ACCESS_KEY=$5

terraform plan -var "manageddiskname=$6"
