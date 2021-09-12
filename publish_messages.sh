#!/bin/bash

set -eux

CURDIR=$(dirname $0)
CURPATH=$(realpath $CURDIR)
PROJECT=$(gcloud config get-value project)

pushd $CURPATH/terraform

INPUT_TOPIC=$(terraform output -raw wordcount-input-topic)

popd

INPUT_TOPIC_FULL="projects/$PROJECT/topics/$INPUT_TOPIC"

for run in {1..20}; do
  gcloud pubsub topics publish $INPUT_TOPIC_FULL --message="$(date +%s) Hello World!"
done
