#!/bin/bash

set -eux

CURDIR=$(dirname $0)
CURPATH=$(realpath $CURDIR)
REGION=$(gcloud config get-value compute/region)
PROJECT=$(gcloud config get-value project)

pushd $CURPATH/terraform

BUCKET_URL=gs://$(terraform output -raw data-bucket-name)
INPUT_TOPIC=$(terraform output -raw wordcount-input-topic)
OUTPUT_TOPIC=$(terraform output -raw wordcount-output-topic)

popd

INPUT_TOPIC_FULL="projects/$PROJECT/topics/$INPUT_TOPIC"

python3 $CURPATH/wordcount_pipeline_streamed.py \
  --runner DataflowRunner \
  --project $PROJECT \
  --region $REGION \
  --temp_location $BUCKET_URL/tmp/ \
  --input_topic $INPUT_TOPIC_FULL \
  --output_topic "projects/$PROJECT/topics/$OUTPUT_TOPIC" \
  --streaming
