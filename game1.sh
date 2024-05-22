gcloud services enable eventarcpublishing.googleapis.com
gcloud services enable eventarc.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable run.googleapis.com


YOUR_BUCKET_NAME="memories-bucket-qwiklabs-gcp-01-f7b9c8fd0f9e"
MY_REGION="us-east1"
YOUR_TOPIC_NAME="memories-topic-646 "

gcloud storage buckets create gs://${YOUR_BUCKET_NAME} --location=${MY_REGION}

gcloud pubsub topics create $YOUR_TOPIC_NAME




#######################

gcloud services enable fitness.googleapis.com
export OAUTH2_TOKEN=$(gcloud auth print-access-token)

echo '{  
   "name": "qwiklabs-gcp-01-748331325d87-bucket-1",
   "location": "us",
   "storageClass": "multi_regional"
}
' > values.json

curl -X POST --data-binary @values.json \
    -H "Authorization: Bearer $OAUTH2_TOKEN" \
    -H "Content-Type: application/json" \
    "https://www.googleapis.com/storage/v1/b?project=$DEVSHELL_PROJECT_ID"

echo '{  
   "name": "qwiklabs-gcp-01-748331325d87-bucket-2",
   "location": "us",
   "storageClass": "multi_regional"
}' > values.json

curl -X POST --data-binary @values.json \
    -H "Authorization: Bearer $OAUTH2_TOKEN" \
    -H "Content-Type: application/json" \
    "https://www.googleapis.com/storage/v1/b?project=$DEVSHELL_PROJECT_ID"







curl -X POST --data-binary @./map.jpg \
    -H "Authorization: Bearer $OAUTH2_TOKEN" \
    -H "Content-Type: image/png" \
    "https://www.googleapis.com/upload/storage/v1/b/$DEVSHELL_PROJECT_ID-bucket-1/o?uploadType=media&name=demo-image"



curl -X POST \
  -H "Authorization: Bearer $OAUTH2_TOKEN" \
  -H "Content-Length: 0" \
  "https://storage.googleapis.com/storage/v1/b/$DEVSHELL_PROJECT_ID-bucket-1/o/demo-image/rewriteTo/b/$DEVSHELL_PROJECT_ID-bucket-2/o/demo-image"





echo '{
  "entity": "allUsers",
  "role": "READER"
}
' > gcs_acl.json

curl -X POST --data-binary @gcs_acl.json \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://storage.googleapis.com/storage/v1/b/$DEVSHELL_PROJECT_ID-bucket-1/o/demo-image/acl"




curl -X DELETE \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://storage.googleapis.com/storage/v1/b/$DEVSHELL_PROJECT_ID-bucket-1/o/demo-image"

curl -X DELETE \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://storage.googleapis.com/storage/v1/b/$DEVSHELL_PROJECT_ID-bucket-1/"





#####################


monitoring.googleapis.com

curl -LO raw.githubusercontent.com/quiccklabs/Labs_solutions/master/Streaming%20Analytics%20into%20BigQuery:%20Challenge%20Lab/techcps106.sh
  

 

export ZONE=

curl -LO raw.githubusercontent.com/Techcps/GSP-Short-Trick/master/Manage%20Bigtable%20on%20Google%20Cloud:%20Challenge%20Lab/techcps380.sh
sudo chmod +x techcps380.sh
./techcps380.sh