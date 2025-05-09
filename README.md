# arr-scripts

A collection of scripts related to the *arrs (Radarr, Sonarr, etc.), Usenet (SABnzbd), Jellyfin, Jellyseerr, cross-seed and more.

---

## 📂 Available Scripts

### 🔹 [Jellyfin - Featured Content](./jellyfin/Featured%20Content/README.md)

Generates a list of recently released media (last 30 days) and formats it for [Jellyfin Media Bar](https://github.com/MakD/Jellyfin-Media-Bar).  
Script: [`create_featured_list.sh`](./jellyfin/Featured%20Content/create_featured_list.sh)

#### Example:
![image](https://github.com/user-attachments/assets/141f6da5-b238-4721-b7b8-e395d2fbbaae)


### 🔹 [Sonarr](./sonarr/)

The script scans the Sonarr download queue for items stuck after failed imports (e.g., "No files found") and deletes them automatically.  
Script: [`clear_queue.sh`](./sonarr/clear_queue/)

The script scans the Sonarr queue for stuck downloads marked as completed but not imported, and attempts to manually import them using the API.  
Script: [`import_stuck_items.sh`](./sonarr/import_stuck_items/)


### 🔹 [Radarr](./radarr/)

The script scans the Radarr download queue for items stuck after failed imports (e.g., "No files found") and deletes them automatically.  
Script: [`clear_queue.sh`](./radarr/clear_queue/)

---

Each subfolder contains its own `README.md` with setup instructions and usage examples.
