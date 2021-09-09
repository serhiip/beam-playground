#!/bin/bash

set -eux

DEFAULT_SERVICE_ACCOUNT=$(gcloud iam service-accounts list --filter=compute | awk '{print $6}' | xargs)
K8S_ZONES=["\"europe-west6-a"\"]
REGION=$(gcloud config get-value compute/region)
PROJECT=$(gcloud config get-value project)

terraform destroy \
          -var="project_id=$PROJECT" \
          -var="region=$REGION" \
          -var="zones=$K8S_ZONES" \
          -var="default_service_account=$DEFAULT_SERVICE_ACCOUNT" \
          -var="k8s_version=1.17.15-gke.800" \

rm -Rf ./.terraform
rm -f ./terraform.tfstate
