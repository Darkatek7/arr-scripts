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

Script related to managing Sonarr, removing stuck download queues.  
Script: [`clear_queue.sh`](./sonarr/clear_queue/)

Script related to managing Sonarr, importing stuck downloads.  
Script: [`import_stuck_items.sh`](./sonarr/import_stuck_items/)


### 🔹 [Radarr](./radarr/)

Script related to managing Radarr, removing stuck download queues.  
Script: [`clear_queue.sh`](./radarr/clear_queue/)

---

Each subfolder contains its own `README.md` with setup instructions and usage examples.
