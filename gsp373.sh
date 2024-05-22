#!/usr/bin/bash

export REGION=us-east4

echo "Starting" "Execution"

gcloud auth list
gcloud services enable iap.googleapis.com
gcloud config set project $DEVSHELL_PROJECT_ID

git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git
cd python-docs-samples/appengine/standard_python3/hello_world/
gcloud app create --project=$(gcloud config get-value project) --region=$REGION
gcloud app deploy --quiet

export AUTH_DOMAIN=$(gcloud config get-value project).uc.r.appspot.com
echo $AUTH_DOMAIN


echo -e  "Use above value to create External domain for OAuth token, domain name as above"
echo -e "Then, enable IAP on App Engine and test" 
echo -e "in next step, add TEST user with IAP-web user access and test "


