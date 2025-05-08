# 🧹 Radarr Queue Cleaner

This Bash script helps maintain a clean and healthy Radarr download queue by automatically detecting and optionally removing **stuck** queue items that Radarr fails to clear on its own.

---

## 🔍 What It Does

The script performs one main cleanup operations:

### 1. Stuck Downloads After Import Failure

Detects downloads that:
- Are marked as `completed`
- Have `timeleft: 00:00:00`
- Are stuck with `trackedDownloadStatus: warning` or `importPending`
- Show errors like:  
  `"No files found are eligible for import"`

These are **stuck in the queue** and can optionally be **automatically removed**.

---

## 🚀 Usage Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/darkatek7/arr-scripts.git
cd radarr
```

### 2. Configure the Script
Edit the clear_queue.sh file:
 ```bash
RADARR_URL="http://localhost:8989"
API_KEY="your_radarr_api_key"
```

### 3. Run the Script Manually
```bash
bash clear_queue.sh
```

_optional:_ perform a dry run to see what would be deleted without actually deleting the items.
```bash
bash clear_queue.sh --dry-run
```

The script will:
* List and remove duplicate episodes from the queue
* Detect and remove stuck downloads after failed imports

Run this script via a crontab scheduled to run every 1 hour and you won't have to worry about stuck downloads again.

---

#### Sample output:
```bash
bash clear_queue.sh 
Checking for stuck queue items...
⚠️  Stuck item detected:
  ID: 15595483
  Title: Stuck-Item
  Output Path: /downloads/Stuck-Item/
  Message: No files found are eligible for import in /downloads/Stuck-Item/

Deleting stuck item ID: 15595483...
Response code: 200
```

Explanation:
* ⚠️ Stuck item detected: The script identifies an item that is stuck (completed with no valid files for import).
* ID: The unique identifier of the stuck item.
* Title: The title of the episode or download.
* Output Path: The location where the download resides.
* Message: A description explaining why the item is stuck (e.g., "No files found are eligible for import").
* Deleting stuck item: The script deletes the item from the queue.
* Response code: Indicates the status of the deletion (200 means success).
