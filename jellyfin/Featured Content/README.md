# Jellyfin Featured Media List Generator

This is a simple Bash script that generates a list of recently released media items (movies and TV episodes) from your Jellyfin server and saves their IDs to a text file. The list is formatted for use with the [Jellyfin Media Bar](https://github.com/MakD/Jellyfin-Media-Bar) plugin, allowing you to highlight new content on your Jellyfin dashboard.

## Features

- Fetches items released in the past 30 days
- Includes both movies and episodes (converts episode IDs to series IDs)
- Outputs a deduplicated list of media IDs
- Automatically writes to the file used by the Media Bar: `/usr/share/jellyfin/web/avatars/list.txt`

## Prerequisites

- A running Jellyfin server
- `jq` installed for JSON processing
- An active Jellyfin API key

## Configuration

Before running the script, open `create_featured_list.sh` and configure the following variables:

```bash
JELLYFIN_SERVER="http://localhost:8096"  # Your Jellyfin server URL
API_KEY="your_api_key_here"             # Replace with your actual API key
```

## Usage 
Make the script executable:

```bash
chmod +x create_featured_list.sh
```
Then run it using Bash:

```bash
./create_featured_list.sh
```

The script will:
* Query the Jellyfin API for all movies and episodes.
* Filter for items released in the last 30 days.
* Extract the item ID (or Series ID for episodes).

Output the results to:

```swift
/usr/share/jellyfin/web/avatars/list.txt
```
This output file is automatically read by the Jellyfin Media Bar.

## Example Output (list.txt)
```nginx
Releases in the past 30 days
12345
67890
abcde
```
Each line after the header is a media ID that Jellyfin Media Bar can feature.
