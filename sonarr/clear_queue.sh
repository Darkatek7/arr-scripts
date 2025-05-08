#!/bin/bash
#
# 🧹 Sonarr Queue Stuck Item Cleaner
#
# This script connects to the Sonarr API and checks the download queue for items that are
# stuck after a failed import. These are typically downloads that:
#   - Have `status: completed`
#   - Show `timeleft: 00:00:00` (fully downloaded)
#   - Have `trackedDownloadStatus: warning` OR `trackedDownloadState: importPending`
#   - Include a status message such as "No files found"
#
# Such items are likely completed downloads that Sonarr failed to import (e.g., missing or moved files).
# The script identifies these stuck queue items and automatically deletes them from the queue using:
#   DELETE /api/v3/queue/{id}
#
# ⚠️ Deletion is ENABLED by default. To disable it, comment out the deletion lines.
#
# Requirements:
#   - bash
#   - curl
#   - jq
#
# Usage:
#   - Configure SONARR_URL and API_KEY below
#   - Run manually: `bash clear_queue.sh`
#   - Run manually: `bash clear_queue.sh --dry-run` to perform a dry run
#   - Or schedule with cron to run automatically
#

# Sonarr settings
SONARR_URL="http://localhost:8989"
API_KEY="key"

# Default mode is delete (not dry-run)
DRY_RUN=false

# Function to fetch the queue
fetch_queue() {
  curl -s -H "X-Api-Key: $API_KEY" "$SONARR_URL/api/v3/queue"
}

# Parse arguments
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      # Unknown arguments
      echo "Unknown argument: $arg"
      exit 1
      ;;
  esac
done

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

    if [ "$DRY_RUN" = true ]; then
      # In dry-run mode, just print what would be deleted
      echo "This item would be deleted in delete mode."
    else
      # In delete mode, actually delete the item
      echo "Deleting stuck item ID: $id..."
      response=$(curl -s -w "%{http_code}" -o /dev/null -X DELETE -H "X-Api-Key: $API_KEY" "$SONARR_URL/api/v3/queue/$id")
      echo "Response code: $response"
    fi
  fi
done
