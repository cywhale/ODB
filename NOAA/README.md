# NOAA Dataset Downloader

This is a unified Python tool for downloading NOAA public datasets from the THREDDS or HTML directory listing, with support for:

- 🧭 Navigating `catalog.html` of THREDDS servers
- 🪂 Recursively downloading `.nc`, `.txt`, `.asc`, `.ruv` and other file types
- 📦 Preserving the NOAA dataset directory structure
- 🔄 Recovering from download failures with `--fix` mode
- 🚧 Handling non-THREDDS (HTML-only) datasets like `hfradar`

---

## 🔧 Requirements

- Python 3.8+
- `beautifulsoup4`, `requests`, `lxml`
- Sudo/root access if writing to `/media/X` or other protected paths

Install dependencies:
```bash
pip install beautifulsoup4 requests lxml
```

For our default storage, it needs sudo privilege
```bash
sudo python3 -m venv /opt/noaavenv
sudo /opt/noaavenv/bin/pip install requests beautifulsoup4 lxml
## after the installation, execute your script like this way:
sudo /opt/noaavenv/bin/python your_script.py
```

---

## 🚀 Usage

### Basic command:

```bash
sudo python3 get_noaa.py --database <ndbc|ncei> --data <dataset> [--date YYYY-MM] [--type ext1,ext2]
```

---

## 📂 Dataset Options

| `--database` | `--data`                        | Description |
|--------------|----------------------------------|-------------|
| `ndbc`       | `cmanwx`, `co-ops`, `oceansites`, `tao-buoy`, `tao-ctd`, `hfradar`, etc. | Marine Buoy + Radar |
| `ncei`       | `gocd`                          | Global Ocean Currents Data |

---

## 🔍 Examples

### Download all `.nc` files from NDBC `cmanwx`

```bash
sudo python3 get_noaa.py --database ndbc --data cmanwx
```

### Download only March 2025 `.nc` files from NDBC `cmanwx`

```bash
sudo python3 get_noaa.py --database ndbc --data cmanwx --date 2025-03
```

### Download all `.txt` metadata from `oceansites`

```bash
sudo python3 get_noaa.py --database ndbc --data oceansites --type txt
```

### Download `.asc` and `.ruv` from NDBC `hfradar` (non-THREDDS)

```bash
sudo python3 get_noaa.py --database ndbc --data hfradar --type asc,ruv
```

### Redownload failed files from logs (all datasets)

```bash
sudo python3 get_noaa.py --fix
```

---

## 💡 Behavior Notes

- Data is saved under:
  ```
  /media/X/NOAA/{database}/{dataset}/...
  ```
  Example: `/media/X/NOAA/ndbc/cmanwx/2025/03/*.nc`

- THREDDS `catalog.html` structure is used when available.
- If missing (e.g., `hfradar`), falls back to recursive HTML crawling.
- Redownload failures are logged to `data_lost_filelist.log` in the corresponding folder.

---

## 📁 Directory Examples

```
/media/X/NOAA/
├── ndbc/
│   ├── cmanwx/2025/03/*.nc
│   ├── oceansites/DATA/ANTARES/oceansites_index.txt
│   └── hfradar/radial/.../*.ruv
└── ncei/
    └── gocd/a0000123/gocd_a0000123_46078_202001.nc
```

---

## 🔧 Developer Notes

You can easily extend the supported datasets by:
- Adding to `DATABASES` in the script
- Adding new layout types to `LAYOUT_MAP` if needed (`year_month`, `nested`)

---

## 🛠 Author & Maintenance

Designed by cywhale, Ocean Data Bank (ODB, Taiwan) for robust NOAA dataset preservation.

