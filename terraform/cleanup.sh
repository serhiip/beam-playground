#!/bin/bash

set -eux

terraform destroy

rm -Rf ./.terraform
rm -f ./terraform.tfstate
