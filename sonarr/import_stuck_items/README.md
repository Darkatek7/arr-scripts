# 📥 Sonarr Manual Import Fixer

This bash script scans your Sonarr queue for downloads that are stuck in an `importPending` state, attempts to resolve custom format (CF) conflicts by deleting lower-score existing files, and triggers a manual import for the newly downloaded file — **automatically**.

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
3. Retries the import via Sonarr's `/manualimport` API endpoint.

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
   cd sonarr-import-fixer

2. **Edit the script**

Open import_stuck_items.sh and configure these two variables:

```bash
SONARR_URL="http://localhost:8989"  # Your Sonarr instance
API_KEY="your-sonarr-api-key"       # Your API key from Sonarr > Settings > General
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
* Uses Sonarr’s internal manual import logic
* Output formatted for readability
* Adds a retry after deletion to allow Sonarr to re-scan

---

## ⚠️ Notes
* Use responsibly: the script will delete episode files if Sonarr reports they are blocking an import.
* Always test with a dry run or on non-critical files first.
* Designed for Sonarr v3 API.

---

## 🧑‍💻 Contributions
Feel free to open an issue or pull request for improvements, bug fixes, or feature suggestions.
