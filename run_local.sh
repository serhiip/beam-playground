#!/bin/bash

set -eux

echo "this is just a text with text written twice" > ./in.txt

python3 ./test_pipeline.py --input ./in.txt --output ./out.txt
