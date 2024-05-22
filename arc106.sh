
export myProject="qwiklabs-gcp-01-57bc850b6f15"
export REGION="us-east4"
export myBucket="$myProject"
export myBqDataset="sensors_643"
export myBqTable="temperature_346"
export myPubTopic="sensors-temp-30232"
export mySubSubscr="${myPubTopic}-sub"
export myDfJob="dfjob-12364"

gcloud services enable dataflow.googleapis.com 

gcloud storage buckets create gs://$myBucket --location=US

bq --location=US mk -d \
    --description "This is my dataset." \
    $myBqDataset

bq mk -t \
  --description "This is my table" \
  $myBqDataset.$myBqTable \
  data:STRING

gcloud pubsub topics create $myPubTopic
gcloud pubsub subscriptions create $mySubSubscr --topic=$myPubTopic

gcloud dataflow jobs run $myDfJob-1 \
  --gcs-location gs://dataflow-templates-$REGION/latest/PubSub_to_BigQuery \
  --region $REGION \
  --staging-location gs://$DEVSHELL_PROJECT_ID/temp \
  --parameters inputTopic=projects/$DEVSHELL_PROJECT_ID/topics/$myPubTopic,outputTableSpec=$DEVSHELL_PROJECT_ID:$myBqDataset.$myBqTable



