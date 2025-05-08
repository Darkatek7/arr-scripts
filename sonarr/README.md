# 🧹 Sonarr Queue Cleaner

This Bash script helps maintain a clean and healthy Sonarr download queue by automatically detecting and optionally removing **stuck** queue items that Sonarr fails to clear on its own.

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
git clone https://github.com/yourusername/sonarr-queue-cleaner.git
cd sonarr-queue-cleaner
```

### 2. Configure the Script
Edit the clear_queue.sh file:
 ```bash
SONARR_URL="http://localhost:8989"
API_KEY="your_sonarr_api_key"
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
