#!/bin/bash

set -eux

CURDIR=$(dirname $0)
ROOT=$(realpath $CURDIR)
REGION=$(gcloud config get-value compute/region)
PROJECT=$(gcloud config get-value project)
pushd $ROOT/terraform
BUCKET_URL=gs://$(terraform output -raw data-bucket-name)
popd

source $ROOT/venv/bin/activate

pip install -r $ROOT/requirements.txt

gsutil cp gs://dataflow-samples/shakespeare/kinglear.txt $ROOT/kinglear.txt

for run in {1..5}; do
  cat $ROOT/kinglear.txt > /tmp/kinglear.txt && cat /tmp/kinglear.txt >> kinglear.txt
done

ls -lah $ROOT/kinglear.txt

gsutil cp $ROOT/kinglear.txt $BUCKET_URL/ && \
    gsutil ls $BUCKET_URL/

rm $ROOT/kinglear.txt
rm /tmp/kinglear.txt

python3 $ROOT/test_pipeline.py \
        --input $BUCKET_URL/kinglear.txt \
        --output $BUCKET_URL/counts \
        --runner DataflowRunner \
        --project $PROJECT \
        --region $REGION \
        --temp_location $BUCKET_URL/tmp/

deactivate
