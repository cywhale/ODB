import os
import sys
import time
import argparse
import requests
from bs4 import BeautifulSoup
from datetime import datetime
from urllib.parse import urlparse, parse_qs, urljoin
import platform

DATABASES = {
    'ndbc': {
        'BASE_FILESERVER_URL': "https://www.ncei.noaa.gov/thredds-ocean/fileServer/ndbc",
        'BASE_CATALOG_URL': "https://www.ncei.noaa.gov/thredds-ocean/catalog/ndbc",
        'BASE_HTTP_URL': "https://www.ncei.noaa.gov/data/oceans/ndbc"
    },
    'ncei': {
        'BASE_FILESERVER_URL': "https://www.ncei.noaa.gov/thredds-ocean/fileServer/ncei",
        'BASE_CATALOG_URL': "https://www.ncei.noaa.gov/thredds-ocean/catalog/ncei",
        'BASE_HTTP_URL': "https://www.ncei.noaa.gov/data/oceans/ncei"
    }
}

HEADERS = {'User-Agent': 'Mozilla/5.0'}

LAYOUT_MAP = {
    'cmanwx': 'year_month',
    'co-ops': 'year_month',
    'tao-buoy': 'year_month'
}

def parse_args():
    parser = argparse.ArgumentParser(description="Download NOAA NetCDF or ASCII data by database and dataset.")
    parser.add_argument('--database', help='Database name, e.g., ndbc, ncei')
    parser.add_argument('--data', help='Dataset name under the database')
    parser.add_argument('--date', help='Optional date in format YYYY-MM to download only one month')
    parser.add_argument('--type', help='Only download files with specific extension, e.g., txt')
    parser.add_argument('--fix', action='store_true', help='Retry download from lost file list')
    return parser.parse_args()

def download_file(url, save_path):
    if os.path.exists(save_path):
        print(f"[SKIP] {save_path} already exists")
        return
    try:
        if not os.path.exists(os.path.dirname(save_path)):
            os.makedirs(os.path.dirname(save_path))
        print(f"[DOWNLOADING] {url}")
        r = requests.get(url, headers=HEADERS, stream=True, timeout=15)
        r.raise_for_status()
        with open(save_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f"[SAVED] {save_path}")
    except Exception as e:
        print(f"[ERROR] Failed to download {url}: {e}")
        with open(os.path.join(os.path.dirname(save_path), "data_lost_filelist.log"), 'a') as log_file:
            log_file.write(f"{url}\n")

def crawl_http_directory(base_url, save_root, file_type_filter=None):
    try:
        r = requests.get(base_url, headers=HEADERS, timeout=10)
        r.raise_for_status()
        soup = BeautifulSoup(r.text, 'lxml')
        links = soup.find_all('a', href=True)

        for a in links:
            href = a['href']
            if href.startswith('?') or href.startswith('..') or href.startswith('#') or not href.strip():
                continue
            if href.startswith('/') or href.startswith('http'):
                continue
            full_url = urljoin(base_url, href)
            if href.endswith('/'):
                subdir = os.path.join(save_root, href.strip('/'))
                crawl_http_directory(full_url, subdir, file_type_filter)
            else:
                if file_type_filter and not any(href.endswith(ext) for ext in file_type_filter):
                    continue
                rel_path = full_url.split('/data/oceans/')[-1]
                save_path = os.path.join("/media/X/NOAA", rel_path)
                download_file(full_url, save_path)
    except Exception as e:
        print(f"[ERROR] Failed to crawl {base_url}: {e}")

def fix_lost_downloads():
    basedir = "d:/backup/NOAA/bak_log" if platform.system() == "Windows" else "/media/X/NOAA/bak_log"
    for fname in os.listdir(basedir):
        if fname.startswith("data_lost_filelist_") and fname.endswith(".log"):
            with open(os.path.join(basedir, fname)) as f:
                for line in f:
                    url = line.strip()
                    if not url:
                        continue
                    parts = url.split("/thredds-ocean/fileServer/")[-1].split("/", 2)
                    if len(parts) < 2:
                        print(f"[WARNING] Cannot parse URL: {url}")
                        continue
                    database, dataset_rest = parts[0], parts[1]
                    save_path = os.path.join("/media/X/NOAA", database, dataset_rest)
                    download_file(url, save_path)

def main():
    args = parse_args()

    if args.fix:
        fix_lost_downloads()
        return

    database = args.database.strip("/")
    dataset = args.data.strip("/")

    db_info = DATABASES.get(database)
    if not db_info:
        print(f"[ERROR] Unknown database: {database}")
        sys.exit(1)

    savedir = "d:/backup/NOAA" if platform.system() == "Windows" else "/media/X/NOAA"
    save_root = os.path.join(savedir, database, dataset)

    file_type_filter = [f".{ext.strip()}" for ext in args.type.split(",")] if args.type else None
    layout = LAYOUT_MAP.get(dataset, "nested")

    base_fileserver_url = f"{db_info['BASE_FILESERVER_URL']}/{dataset}"
    catalog_root_url = f"{db_info['BASE_CATALOG_URL']}/{dataset}"
    base_http_url = f"{db_info['BASE_HTTP_URL']}/{dataset}/"

    try:
        # Check if catalog.html exists
        test_catalog = f"{catalog_root_url}/catalog.html"
        r = requests.head(test_catalog, timeout=5)
        r.raise_for_status()
        # If layout is year_month, handle that way
        if layout == "year_month":
            if args.date:
                try:
                    dt = datetime.strptime(args.date, "%Y-%m")
                    year, month = dt.year, dt.month
                    run_for_month(base_fileserver_url, catalog_root_url, save_root, year, month, file_type_filter)
                except ValueError:
                    print("[ERROR] Invalid date format. Use YYYY-MM (e.g., 2025-02)")
            else:
                run_all(base_fileserver_url, catalog_root_url, save_root, file_type_filter)
        else:
            crawl_and_download(base_fileserver_url, catalog_root_url, save_root, dataset, file_type_filter)
    except Exception:
        # Fallback to HTML crawling mode
        print("[INFO] Falling back to direct HTTP directory crawling mode...")
        crawl_http_directory(base_http_url, save_root, file_type_filter)

if __name__ == "__main__":
    main()
