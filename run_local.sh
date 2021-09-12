#!/bin/bash

set -eux

CURDIR=$(dirname $0)
CURPATH=$(realpath $CURDIR)

source $CURPATH/venv/bin/activate

echo "this is just a text with text written twice" > ./in.txt

python3 ./test_pipeline.py --input ./in.txt --output ./out.txt

deactivate
