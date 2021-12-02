#!/bin/bash

set -eux

CURDIR=$(dirname $0)
CURPATH=$(realpath $CURDIR)
REGION=$(gcloud config get-value compute/region)
PROJECT=$(gcloud config get-value project)

#terraform destroy \
#          -var="project_id=$PROJECT" \
#          -var="region=$REGION" \

rm -Rf $CURPATH/.terraform
rm -f $CURPATH/terraform.tfstate
