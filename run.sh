#!/bin/bash

set -eux

# gcloud auth login --update-adc --no-launch-browser
# gcloud config set project

CURDIR=$(dirname $0)
K8S_ZONES=["\"europe-west6-a"\"]
REGION=$(gcloud config get-value compute/region)
PROJECT=$(gcloud config get-value project)
INPUT_FILENAME=in.txt

gcloud services enable dataflow.googleapis.com

pushd $CURDIR/terraform && \
    terraform init && \
    terraform apply \
              -var="project_id=$PROJECT" \
              -var="region=$REGION" \
              -auto-approve

BUCKET_URL=gs://$(terraform output data-bucket-name)

echo "this is just a text with text written twice" > $INPUT_FILENAME && \
    gsutil cp gs://dataflow-samples/shakespeare/kinglear.txt $BUCKET_URL/ && \
    gsutil ls $BUCKET_URL/

rm $INPUT_FILENAME

popd

python test_pipeline.py \
       --input $BUCKET_URL/$INPUT_FILENAME \
       --output $BUCKET_URL/counts \
       --runner DataflowRunner \
       --project $PROJECT \
       --region $REGION \
       --temp_location $BUCKET_URL/tmp/
