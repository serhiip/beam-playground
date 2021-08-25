#!/bin/bash

set -eux

# gcloud auth login --update-adc --no-launch-browser
# gcloud config set project
gcloud config set compute/region europe-west2

CURDIR=$(dirname $0)
CURPATH=$(realpath $CURDIR)
K8S_ZONES=["\"europe-west6-a"\"]
REGION=$(gcloud config get-value compute/region)
PROJECT=$(gcloud config get-value project)
INPUT_FILENAME=$CURPATH/in.txt

gcloud services enable dataflow.googleapis.com

pushd $CURPATH/terraform && \
    terraform init && \
    terraform apply \
              -var="project_id=$PROJECT" \
              -var="region=$REGION" \
              -auto-approve

terraform output

popd
