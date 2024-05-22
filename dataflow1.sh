git clone https://github.com/GoogleCloudPlatform/training-data-analyst
cd /home/jupyter/training-data-analyst/quests/dataflow_python/


bash generate_batch_events.sh



export PROJECT_ID=$(gcloud config get-value project)

python3 my_pipeline.py \
  --project=${PROJECT_ID} \
  --region=Region \
  --runner=DirectRunner \
  --inputPath=gs://$PROJECT_ID/events.json \
  --outputPath=gs://$PROJECT_ID/temp99/  \
  --tableName='${PROJECT_ID}.logs.logs' 



# Set up environment variables
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-west1
export BUCKET=gs://${PROJECT_ID}
export COLDLINE_BUCKET=${BUCKET}-coldline
export PIPELINE_FOLDER=${BUCKET}
export RUNNER=DataflowRunner
export INPUT_PATH=${PIPELINE_FOLDER}/events.json
export OUTPUT_PATH=${PIPELINE_FOLDER}-coldline/pipeline_output
export TABLE_NAME=${PROJECT_ID}:logs.logs_filtered

cd $BASE_DIR
python3 my_pipeline.py \
--project=${PROJECT_ID} \
--region=${REGION} \
--stagingLocation=${PIPELINE_FOLDER}/staging \
--tempLocation=${PIPELINE_FOLDER}/temp \
--runner=${RUNNER} \
--inputPath=${INPUT_PATH} \
--outputPath=${OUTPUT_PATH} \
--tableName=${TABLE_NAME}


