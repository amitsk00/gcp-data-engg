


gsutil cp -r gs://spls/gsp050 gs://dataprep-staging-3d82f1bd-02c2-400b-aa2f-2fc5a0db58b7


####################
# Composer

sudo apt-get install -y virtualenv
python3 -m venv venv
source venv/bin/activate

DAGS_BUCKET="us-east4-composer-advanced--5bfb9ebb-bucket"

gcloud composer environments run composer-advanced-lab \
--location us-east4 variables -- \
set table_list_file_path /home/airflow/gcs/dags/bq_copy_eu_to_us_sample.csv

gcloud composer environments run composer-advanced-lab \
--location us-east4 variables -- \
set gcs_source_bucket qwiklabs-gcp-03-5ff5291824a7-us

gcloud composer environments run composer-advanced-lab \
--location us-east4 variables -- \
set gcs_dest_bucket qwiklabs-gcp-03-5ff5291824a7-eu

gcloud composer environments run composer-advanced-lab \
    --location us-east4 variables -- \
    get gcs_source_bucket

cd ~
gcloud storage cp -r gs://spls/gsp283/python-docs-samples .

gcloud storage cp -r python-docs-samples/third_party/apache-airflow/plugins/* gs://$DAGS_BUCKET/plugins

gcloud storage cp python-docs-samples/composer/workflows/bq_copy_across_locations.py gs://$DAGS_BUCKET/dags
gcloud storage cp python-docs-samples/composer/workflows/bq_copy_eu_to_us_sample.csv gs://$DAGS_BUCKET/dags




####################

curl -s -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer '$(gcloud auth print-access-token)'' \
    'https://videointelligence.googleapis.com/v1/projects/487258167656/locations/asia-east1/operations/6350223079369396311'



############################## challenge lab 2


export API_KEY="dummy"



export GOOGLE_CLOUD_PROJECT=$(gcloud config get-value core/project)
gcloud iam service-accounts create my-natlang-sa \
  --display-name "my natural language service account"

gcloud iam service-accounts keys create ~/key.json \
  --iam-account my-natlang-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS="/home/$USER/key.json"

gcloud ml language analyze-entities --content="Old Norse texts portray Odin as one-eyed and long-bearded, frequently wielding a spear named Gungnir and wearing a cloak and a broad hat." > result.json

gsutil cp result.json   gs://qwiklabs-gcp-00-26bda19dbfaa-marking/task4-cnl-259.result







