#!/bin/bash

set -eux

CURDIR=$(dirname $0)
CURPATH=$(realpath $CURDIR)
REGION=$(gcloud config get-value compute/region)
ZONE=$(gcloud config get-value compute/zone)
PROJECT=$(gcloud config get-value project)

pushd $CURPATH/terraform

BUCKET_URL=gs://$(terraform output -raw data-bucket-name)
INPUT_TOPIC=$(terraform output -raw wordcount-input-topic)
INPUT_SUBSCRIPTION=$(terraform output -raw wordcount-input-subscription)
OUTPUT_TOPIC=$(terraform output -raw wordcount-output-topic)

pushd $CURPATH/scio/

sbt stage

./target/universal/stage/bin/scio \
 --runner=DataflowRunner \
 --project=$PROJECT \
 --zone=$ZONE \
 --inputSubscription=projects/$PROJECT/subscriptions/$INPUT_SUBSCRIPTION \
 --outputTopic=projects/$PROJECT/topics/$OUTPUT_TOPIC

popd && popd
