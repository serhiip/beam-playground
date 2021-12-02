#!/bin/bash

set -eux

CURDIR=$(dirname $0)
CURPATH=$(realpath $CURDIR)

rm -Rf $CURPATH/venv
virtualenv $CURPATH/venv

source $CURPATH/venv/bin/activate

pip uninstall -r $CURPATH/requirements.txt -y
pip install -r $CURPATH/requirements.txt

echo "this is just a text with text written twice" > ./in.txt
echo "this is just a text with text written twice" >> ./in.txt

python3 ./test_pipeline.py --input ./in.txt --output ./out.txt

deactivate
