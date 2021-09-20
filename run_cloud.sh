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

gsutil cp gs://dataflow-samples/shakespeare/kinglear.txt $CURPATH/kinglear.txt

for run in {1..5}; do
  cat $CURPATH/kinglear.txt > /tmp/kinglear.txt && cat /tmp/kinglear.txt >> kinglear.txt
done

ls -lah $CURPATH/kinglear.txt

gsutil cp $CURPATH/kinglear.txt $BUCKET_URL/ && \
    gsutil ls $BUCKET_URL/

rm $CURPATH/kinglear.txt
rm /tmp/kinglear.txt

python3 $CURPATH/test_pipeline.py \
        --input $BUCKET_URL/kinglear.txt \
        --output $BUCKET_URL/counts \
        --runner DataflowRunner \
        --project $PROJECT \
        --region $REGION \
        --temp_location $BUCKET_URL/tmp/

deactivate
