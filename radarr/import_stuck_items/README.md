# 📥 Radarr Manual Import Fixer

This bash script scans your Radarr queue for downloads that are stuck in an `importPending` state, attempts to resolve custom format (CF) conflicts by deleting lower-score existing files, and triggers a manual import for the newly downloaded file — **automatically**.

---

## 🔧 What It Does

The script identifies:

- ✅ Fully downloaded episodes (`timeleft: 00:00:00`)
- ✅ Status: `completed`
- ✅ Still pending import (`trackedDownloadState: importPending`)
- ✅ Not blocked by fatal errors like "No files found"
- ✅ Not already imported (`hasFile: false`)

If a stuck item is found, it:

1. Detects if an existing episode file is blocking import due to Custom Format (CF) score.
2. Deletes the existing file (if needed and allowed).
3. Retries the import via Radarr's `/manualimport` API endpoint.

---

## 🧰 Requirements

Make sure the following are installed on the system running this script:

- `bash`
- `curl`
- [`jq`](https://stedolan.github.io/jq/)
- `python3` (for URL encoding)

---

## ⚙️ Setup

1. **Clone or download the script**

   ```bash
   git clone https://github.com/darkatek7/arr-scripts.git
   cd radarr/import_stuck_items

2. **Edit the script**

Open import_stuck_items.sh and configure these two variables:

```bash
RADARR_URL="http://localhost:8989"  # Your Radarr instance
API_KEY="your-radarr-api-key"       # Your API key from Radarr > Settings > General
```

3. **Make the script executable**

```bash
chmod +x import_stuck_items.sh
```

---

## 🚀 Usage
Run the script:

```bash
./import_stuck_items.sh
```

You’ll see output like:

```mathematica
🔍 Scanning for potentially importable stuck downloads...
⚠️  Importable item possibly stuck:
  ID: 123456
  Title: My.Show.S01E01
  Output Path: /downloads/My.Show.S01E01/
  Message: Not a Custom Format upgrade...
...
✅ Episode file deleted.
✅ Manual import completed.
```

---

## ✅ Features
* Skips already-imported episodes (hasFile: true)
* Auto-deletes blocking episode files if CF score is lower
* Uses Radarr’s internal manual import logic
* Output formatted for readability
* Adds a retry after deletion to allow Radarr to re-scan
* Run this script via a crontab scheduled to run every 1 hour and you won't have to worry about stuck downloads again.

---

## ⚠️ Notes
* Use responsibly: the script will delete episode files if Radarr reports they are blocking an import.
* Always test with a dry run by adding the ```bash import_stuck_items.sh --dry-run``` argument first.
* Designed for Radarr v3 API.

---

## 🧑‍💻 Contributions
Feel free to open an issue or pull request for improvements, bug fixes, or feature suggestions.
