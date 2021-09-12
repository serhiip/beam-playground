#!/bin/bash

set -eux

CURDIR=$(dirname $0)
CURPATH=$(realpath $CURDIR)

terraform destroy

rm -Rf $CURPATH/.terraform
rm -f $CURPATH/terraform.tfstate
