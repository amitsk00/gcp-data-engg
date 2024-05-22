#!/usr/bin/sh 

export API_KEY="AIzaSyCtEIrwdIwQ3m1jTPR7hSr9IDqq2LXq3t4"

TASK_2_REQUEST_FILE="request.json"
TASK_2_RESPONSE_FILE="response.json"

cat > "$TASK_2_REQUEST_FILE"   <<EOF
{
  "config": {
    "encoding": "LINEAR16",
    "languageCode": "en-US",
    "audioChannelCount": 2
  },
  "audio": {
    "uri": "gs://spls/arc131/question_en.wav"
  }
}
EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @"$TASK_2_REQUEST_FILE" \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > "$TASK_2_RESPONSE_FILE"




TASK_3_REQUEST_FILE="request_speech_sp.json"
TASK_3_RESPONSE_FILE="response_sp.json"

cat > "$TASK_3_REQUEST_FILE"   <<EOF
{
  "config": {
    "encoding": "FLAC",
    "languageCode": "es-ES"
  },
  "audio": {
    "uri": "gs://spls/arc131/multi_es.flac"
  }
}
EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @"$TASK_3_REQUEST_FILE" \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > "$TASK_3_RESPONSE_FILE"





