#!/bin/bash

# Sonarr settings
SONARR_URL="http://localhost:8989"
API_KEY="key"

# Function to fetch the queue
fetch_queue() {
  curl -s -H "X-Api-Key: $API_KEY" "$SONARR_URL/api/v3/queue"
}

# Fetch queue
queue=$(fetch_queue)

if [[ -z "$queue" || "$queue" == "null" ]]; then
  echo "Failed to fetch the queue or the queue is empty."
  exit 1
fi

echo "Checking for stuck queue items..."

# Loop through each record
echo "$queue" | jq -c '.records[]' | while read -r item; do
  id=$(echo "$item" | jq -r '.id')
  title=$(echo "$item" | jq -r '.title')
  timeleft=$(echo "$item" | jq -r '.timeleft')
  status=$(echo "$item" | jq -r '.status')
  tracked_status=$(echo "$item" | jq -r '.trackedDownloadStatus')
  download_state=$(echo "$item" | jq -r '.trackedDownloadState')
  status_message=$(echo "$item" | jq -r '.statusMessages[0].messages[0]')
  output_path=$(echo "$item" | jq -r '.outputPath')

  # Conditions for stuck: completed, 0 timeleft, importPending or warning, and status message mentions no importable file
  if [[ "$status" == "completed" && "$timeleft" == "00:00:00" && ( "$tracked_status" == "warning" || "$download_state" == "importPending" ) && "$status_message" == *"No files found"* ]]; then
    echo "⚠️  Stuck item detected:"
    echo "  ID: $id"
    echo "  Title: $title"
    echo "  Output Path: $output_path"
    echo "  Message: $status_message"
    echo ""

    # Optional: uncomment the line below to automatically delete the stuck queue item
    echo "Deleting stuck item ID: $id..."
    response=$(curl -s -w "%{http_code}" -o /dev/null -X DELETE -H "X-Api-Key: $API_KEY" "$SONARR_URL/api/v3/queue/$id")
    echo "Response code: $response"
  fi
done
