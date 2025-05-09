#!/bin/bash
#
# 📥 Sonarr Manual Import Candidate Scanner
#
# This script identifies completed downloads in the Sonarr queue that:
#   - Are fully downloaded (`timeleft: 00:00:00`)
#   - Are marked as completed
#   - Were not auto-imported (`trackedDownloadState: importPending`)
#   - Do NOT include a fatal error like "No files found"
#
# These items may be importable manually and worth reviewing.
#
# Requirements:
#   - bash
#   - curl
#   - jq
#

SONARR_URL="http://localhost:8989"
API_KEY="key"
DRY_RUN=false

# Check for --dry-run flag
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "🧪 Running in DRY RUN mode – no changes will be made."
fi

trigger_import() {
  local path="$1"
  local encoded_path
  encoded_path=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$path'''))")

  echo "🔁 Attempting manual import for: $path"

  import_candidates=$(curl -s -H "X-Api-Key: $API_KEY" "$SONARR_URL/api/v3/manualimport?folder=$encoded_path&downloadedEpisodesOnly=true")

  if [[ -z "$import_candidates" || "$import_candidates" == "[]" ]]; then
    echo "⚠️  No import candidates found in: $path"
    return
  fi

  echo "$import_candidates" | jq -c '.[]' | while read -r candidate; do
    relative_path=$(echo "$candidate" | jq -r '.relativePath')
    path=$(echo "$candidate" | jq -r '.path')
    episode_id=$(echo "$candidate" | jq -r '.episodes[0].id')
    episode_file_id=$(echo "$candidate" | jq -r '.episodes[0].episodeFileId')
    series_id=$(echo "$candidate" | jq -r '.seriesId')
    rejection=$(echo "$candidate" | jq -r '.rejections[0].reason // empty')

    has_file=$(echo "$candidate" | jq -r '.episodes[0].hasFile')
    if [[ "$has_file" == "true" ]]; then
      echo "ℹ️  Skipping: Episode already has file."
      continue
    fi

    echo "📄 Candidate file: $relative_path"

    if [[ "$rejection" == "Not a Custom Format upgrade"* && "$episode_file_id" != "0" ]]; then
      echo "⚠️  Existing episode file is blocking import due to CF score."
      if [[ "$DRY_RUN" == true ]]; then
        echo "🧪 DRY RUN: Would delete episode file ID: $episode_file_id"
      else
        delete_response=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
          -H "X-Api-Key: $API_KEY" \
          "$SONARR_URL/api/v3/episodefile/$episode_file_id")

        if [[ "$delete_response" != "200" ]]; then
          echo "❌ Failed to delete episode file. HTTP $delete_response"
          continue
        else
          echo "✅ Episode file deleted."
        fi
      fi
    fi

    if [[ "$DRY_RUN" == true ]]; then
      echo "🧪 DRY RUN: Would POST import for: $relative_path"
    else
      retry_import_candidates=$(curl -s -H "X-Api-Key: $API_KEY" "$SONARR_URL/api/v3/manualimport?folder=$encoded_path&downloadedEpisodesOnly=true")

      updated_payload=$(echo "$retry_import_candidates" | jq -c --arg rel "$relative_path" 'map(select(.relativePath == $rel)) | map({path: .path, relativePath: .relativePath, import: true})')

      response=$(curl -s -w "\nHTTP Code: %{http_code}\n" -X POST \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: $API_KEY" \
        -d "$updated_payload" \
        "$SONARR_URL/api/v3/manualimport")

      echo "$response"
      sleep 1
    fi
  done
}

# Connectivity check
ping_test=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Api-Key: $API_KEY" "$SONARR_URL/api/v3/system/status")
if [[ "$ping_test" != "200" ]]; then
  echo "❌ Unable to connect to Sonarr. Check URL/API key."
  exit 1
fi

queue=$(curl -s -H "X-Api-Key: $API_KEY" "$SONARR_URL/api/v3/queue")

if [[ -z "$queue" || "$queue" == "null" ]]; then
  echo "❌ Failed to fetch the queue or the queue is empty."
  exit 1
fi

echo "🔍 Scanning for potentially importable stuck downloads..."
FOUND_ANY=false

while read -r item; do
  id=$(echo "$item" | jq -r '.id')
  title=$(echo "$item" | jq -r '.title')
  timeleft=$(echo "$item" | jq -r '.timeleft')
  status=$(echo "$item" | jq -r '.status')
  download_state=$(echo "$item" | jq -r '.trackedDownloadState')
  output_path=$(echo "$item" | jq -r '.outputPath')
  status_message=$(echo "$item" | jq -r '.statusMessages[]?.messages[]? // empty' | head -n 1)

  if [[ "$status" == "completed" && "$timeleft" == "00:00:00" && "$download_state" == "importPending" ]]; then
    FOUND_ANY=true
    echo "⚠️  Importable item possibly stuck:"
    echo "  ID: $id"
    echo "  Title: $title"
    echo "  Output Path: $output_path"
    echo "  Message: ${status_message:-None}"
    echo ""
    trigger_import "$output_path"
  fi
done < <(echo "$queue" | jq -c '.records[]')

if [ "$FOUND_ANY" = false ]; then
  echo "✅ No importable stuck downloads found."
fi
