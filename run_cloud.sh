#!/bin/bash

set -eux

CURDIR=$(dirname $0)
CURPATH=$(realpath $CURDIR)
REGION=$(gcloud config get-value compute/region)
PROJECT=$(gcloud config get-value project)
pushd $CURPATH/terraform
BUCKET_URL=gs://$(terraform output -raw data-bucket-name)
popd

source $CURPATH/venv/bin/activate

gsutil cp gs://dataflow-samples/shakespeare/kinglear.txt $BUCKET_URL/ && \
    gsutil ls $BUCKET_URL/

python3 $CURPATH/test_pipeline.py \
        --input $BUCKET_URL/kinglear.txt \
        --output $BUCKET_URL/counts \
        --runner DataflowRunner \
        --project $PROJECT \
        --region $REGION \
        --temp_location $BUCKET_URL/tmp/

deactivate
