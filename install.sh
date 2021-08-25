#!/bin/bash

set -eux

# need pip > 19.0 as per https://arrow.apache.org/docs/python/install.html#using-pip
pip3 install -U pip==21.2.4
pip3 install -r ./requirements.txt
