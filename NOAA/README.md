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
# This method would fail if it uses THREDDS catalog to analyze files but those catalog.html DO NOT record the extension, e.g., .txt, you want.
sudo python3 get_noaa.py --database ndbc --data oceansites --type txt
```

### Download `.asc` and `.ruv` from NDBC `hfradar` (non-THREDDS)

```bash
sudo python3 get_noaa.py --database ndbc --data hfradar
```

### `--fallback URL` with `--outdir DIR` 
Force the script to crawl and download from a direct HTML directory listing instead of THREDDS, and specify a custom output directory:
```bash
sudo python3 get_noaa.py --fallback https://www.ngdc.noaa.gov/hazard/data/cdroms/EQ_StrongMotion_v1/data/ --outdir /media/X/NOAA/ncei/natural-hazard/earthquakes/EQ_StrongMotion_v1
```

If `--outdir` is provided, the script will automatically append the mapping to:
```
/media/X/NOAA/bak_log/fix_path.txt
```
This ensures future `--fix` operations restore to the correct folder.

### 🔄 `--fix` Mode

When using `--fix`, the script attempts to re-download files listed in:
```
/media/X/NOAA/bak_log/data_lost_filelist_*.log
```

If `/media/X/NOAA/bak_log/fix_path.txt` exists, its mappings will override default save locations:
```
https://base_url_prefix/,/custom/save/path
```

Example:
```
https://www.ngdc.noaa.gov/thredds/fileServer/regional/,/media/X/NOAA/ncei/estuarine_bathymetry
```

This allows `--fix` to correctly restore files to their intended directories.

---

### `--dry-run`
Preview all downloads without saving any files (respected across all modes including `--fix`):
```bash
sudo python3 get_noaa.py --fix --dry-run
sudo python3 get_noaa.py --fallback https://... --outdir ... --dry-run
```

### `--force`
Force downloading to overwrite existed file in the save directory (default would skip it, not overwriting)
```bash
sudo python3 get_noaa.py --fix --force
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
│   └── gocd/a0000123/gocd_a0000123_46078_202001.nc
└── bak_log/
│   ├── fix_path.txt
│   └── data_lost_filelist_xxx.log
```

---

## 🔧 Developer Notes

You can easily extend the supported datasets by:
- Adding to `DATABASES` in the script
- Adding new layout types to `LAYOUT_MAP` if needed (`year_month`, `nested`)

---

## 🛠 Author & Maintenance

Designed by cywhale, Ocean Data Bank (ODB, Taiwan) for robust NOAA dataset preservation.

