#!/bin/bash
#
# 📥 Radarr Manual Import Candidate Scanner
#
# This script identifies completed downloads in the Radarr queue that:
#   - Are fully downloaded
#   - Were not auto-imported
#   - Do not show a fatal error (e.g., "No files found")
#   - Might be importable manually (files are likely present)
#
# Requirements:
#   - bash
#   - curl
#   - jq
#

RADARR_URL="http://localhost:7878"
API_KEY="key"
DRY_RUN=false

# Remove trailing slash if present
RADARR_URL="${RADARR_URL%/}"

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

  import_candidates=$(curl -s -H "X-Api-Key: $API_KEY" "$RADARR_URL/api/v3/manualimport?folder=$encoded_path&downloadedMoviesOnly=true")

  if [[ -z "$import_candidates" || "$import_candidates" == "[]" ]]; then
    echo "⚠️  No import candidates found in: $path"
    return
  fi

  echo "$import_candidates" | jq -c '.[]' | while read -r candidate; do
    relative_path=$(echo "$candidate" | jq -r '.relativePath')
    path=$(echo "$candidate" | jq -r '.path')
    movie_id=$(echo "$candidate" | jq -r '.movies[0].id')
    movie_file_id=$(echo "$candidate" | jq -r '.movies[0].movieFileId')
    rejection=$(echo "$candidate" | jq -r '.rejections[0].reason // empty')

    has_file=$(echo "$candidate" | jq -r '.movies[0].hasFile')
    if [[ "$has_file" == "true" ]]; then
      echo "ℹ️  Skipping: Movie already has file."
      continue
    fi

    echo "📄 Candidate file: $relative_path"

    if [[ "$rejection" == "Not a Custom Format upgrade"* && "$movie_file_id" != "0" ]]; then
      echo "⚠️  Existing movie file is blocking import due to CF score."
      if [[ "$DRY_RUN" == true ]]; then
        echo "🧪 DRY RUN: Would delete movie file ID: $movie_file_id"
      else
        delete_response=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
          -H "X-Api-Key: $API_KEY" \
          "$RADARR_URL/api/v3/moviefile/$movie_file_id")

        if [[ "$delete_response" != "200" ]]; then
          echo "❌ Failed to delete movie file. HTTP $delete_response"
          continue
        else
          echo "✅ Movie file deleted."
        fi
      fi
    fi

    if [[ "$DRY_RUN" == true ]]; then
      echo "🧪 DRY RUN: Would POST import for: $relative_path"
    else
      retry_import_candidates=$(curl -s -H "X-Api-Key: $API_KEY" "$RADARR_URL/api/v3/manualimport?folder=$encoded_path&downloadedMoviesOnly=true")

      updated_payload=$(echo "$retry_import_candidates" | jq -c --arg rel "$relative_path" 'map(select(.relativePath == $rel)) | map({path: .path, relativePath: .relativePath, import: true})')

      response=$(curl -s -w "\nHTTP Code: %{http_code}\n" -X POST \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: $API_KEY" \
        -d "$updated_payload" \
        "$RADARR_URL/api/v3/manualimport")

      echo "$response"
      sleep 1
    fi
  done
}

# Connectivity check
ping_test=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Api-Key: $API_KEY" "$RADARR_URL/api/v3/system/status")
if [[ "$ping_test" != "200" ]]; then
  echo "❌ Unable to connect to Radarr. Check URL/API key."
  exit 1
fi

queue=$(curl -s -H "X-Api-Key: $API_KEY" "$RADARR_URL/api/v3/queue")

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

  if [[ "$status" == "completed" && "$timeleft" == "00:00:00" && "$download_state" == "importBlocked" ]]; then
  echo "🗑 Import is blocked. Deleting download: $title"
  FOUND_ANY=true
    if [[ "$DRY_RUN" == true ]]; then
      echo "🧪 DRY RUN: Would delete download ID: $id"
    else
      delete_response=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
        -H "X-Api-Key: $API_KEY" \
        "$RADARR_URL/api/v3/queue/$id")
      if [[ "$delete_response" != "200" ]]; then
        echo "❌ Failed to delete stuck download. HTTP $delete_response"
      else
        echo "✅ Deleted stuck download."
      fi
    fi

elif [[ "$status" == "completed" && "$timeleft" == "00:00:00" && "$download_state" == "importPending" ]]; then
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
