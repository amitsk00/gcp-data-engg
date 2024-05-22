#!/usr/bin/sh

export ZONE="us-east5-a"
export REGION="${ZONE%-*}"

export myBigTable="ecommerce-recommendations"
export myBtZone="us-east5-a"
export myBtStorage="SSD"
export myBtMinInstance="1"
export myBtMaxInstance="5"
export myBtPctCpu="60"



gcloud services disable dataflow.googleapis.com --project $DEVSHELL_PROJECT_ID
export PROJECT_ID=$(gcloud config get-value project)
gcloud services enable dataflow.googleapis.com --project $DEVSHELL_PROJECT_ID
sleep 10

gsutil mb gs://$PROJECT_ID
export PROJECT_ID=$(gcloud config get-value project)



gcloud bigtable instances create ${myBigTable} \
    --project $PROJECT_ID \
    --display-name "${myBigTable}" \
    --cluster-storage-type ${myBtStorage} \
    --cluster-config id="${myBigTable}-c1",zone=${myBtZone}, nodes=1 , \
        autoscaling-min-nodes=${myBtMinInstance} , \
        autoscaling-max-nodes=${myBtMaxInstance} , \
        autoscaling-cpu-target=${myBtPctCpu} 



gcloud bigtable clusters create "${myBigTable}-c2" \
    --project=$PROJECT_ID \
    --async \
    --instance="${myBigTable}" \
    --zone=4{myBtZone} \
    --num-nodes=1 \
    --autoscaling-min-nodes=${myBtMinInstance}, \
    --autoscaling-max-nodes=${myBtMaxInstance}, \
    --autoscaling-cpu-target=${myBtPctCpu} \
    --autoscaling-storage-target=${myBtStorage} 



gcloud bigtable instances tables create SessionHistory \
    --instance=${myBigTable} \
    --project=$PROJECT_ID \
    --column-families=Engagements,Sales

while true; do
    gcloud dataflow jobs run import-sessions \
        --region=$REGION \
        --project=$PROJECT_ID \
        --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable \
        --staging-location gs://$PROJECT_ID/temp \
        --parameters bigtableProject=$PROJECT_ID,bigtableInstanceId=${myBigTable},bigtableTableId=SessionHistory,sourcePattern=gs://cloud-training/OCBL377/retail-engagements-sales-00000-of-00001,mutationThrottleLatencyMs=0

    if [ $? -eq 0 ]; then
        echo "Job has completed successfully. now just wait for succeeded .."
        break
    else
        echo "Job failed. "
        sleep 10
    fi
done


gcloud bigtable instances tables create PersonalizedProducts \
    --project=$PROJECT_ID \
    --instance=${myBigTable} \
    --column-families=Recommendations

while true; do
    gcloud dataflow jobs run import-recommendations \
        --region=$REGION \
        --project=$PROJECT_ID \
        --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable \
        --staging-location gs://$PROJECT_ID/temp \
        --parameters bigtableProject=$PROJECT_ID,bigtableInstanceId=${myBigTable},bigtableTableId=PersonalizedProducts,sourcePattern=gs://cloud-training/OCBL377/retail-recommendations-00000-of-00001,mutationThrottleLatencyMs=0

    if [ $? -eq 0 ]; then
        echo "Job has completed successfully.  ."
        break
    else
        echo "Job failed.  "
        sleep 10
    fi
done


gcloud beta bigtable backups create PersonalizedProducts_7 \
    --instance=${myBigTable} \
    --cluster=${myBigTable}-c1 \
    --table=PersonalizedProducts \
    --retention-period=7d 


gcloud beta bigtable instances tables restore \
    --source=projects/$PROJECT_ID/instances/${myBigTable}/clusters/${myBigTable}-c1/backups/PersonalizedProducts_7 \
    --async \
    --destination=PersonalizedProducts_7_restored \
    --destination-instance=${myBigTable} \
    --project=$PROJECT_ID

sleep 60





while true; do
    gcloud dataflow jobs run import-sessions \
        --region=$REGION \
        --project=$PROJECT_ID \
        --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable \
        --staging-location gs://$PROJECT_ID/temp \
        --parameters bigtableProject=$PROJECT_ID,bigtableInstanceId=${myBigTable},bigtableTableId=SessionHistory,sourcePattern=gs://cloud-training/OCBL377/retail-engagements-sales-00000-of-00001,mutationThrottleLatencyMs=0

    if [ $? -eq 0 ]; then
        echo "Job has completed successfully. ."
        break
    else
        echo "Job failed.  "
        sleep 10
    fi
done


sleep 10




while true; do
    gcloud dataflow jobs run import-recommendations \
        --region=$REGION \
        --project=$PROJECT_ID \
        --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable \
        --staging-location gs://$PROJECT_ID/temp \
        --parameters bigtableProject=$PROJECT_ID,bigtableInstanceId=${myBigTable},bigtableTableId=PersonalizedProducts,sourcePattern=gs://cloud-training/OCBL377/retail-recommendations-00000-of-00001,mutationThrottleLatencyMs=0

    if [ $? -eq 0 ]; then
        echo "Job has completed successfully. "
        break
    else
        echo "Job failed.  "
        sleep 10
    fi
done


