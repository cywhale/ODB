import os
import sys
import time
import argparse
import requests
from bs4 import BeautifulSoup
from datetime import datetime
from urllib.parse import urlparse, parse_qs, urljoin
import platform
import re

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

# Global variable to store the centralized log path
GLOBAL_LOG_PATH = None
# Global variable to store the minimum year filter
MIN_YEAR = None

def parse_args():
    parser = argparse.ArgumentParser(description="Download NOAA NetCDF or ASCII data by database and dataset.")
    parser.add_argument('--database', help='Database name, e.g., ndbc, ncei')
    parser.add_argument('--data', help='Dataset name under the database')
    parser.add_argument('--year', help='Start from this year and skip earlier years (e.g., 2007)')
    parser.add_argument('--type', help='Only download files with specific extension, e.g., txt')
    parser.add_argument('--fix', action='store_true', help='Retry download from lost file list')
    parser.add_argument('--fallback', help='Force fallback mode and crawl from given URL')
    parser.add_argument('--outdir', help='Specify output directory when using --fallback')
    parser.add_argument('--dry-run', action='store_true', help='Preview download paths without downloading')
    parser.add_argument('--force', action='store_true', help='Force overwrite existing files during any download')
    return parser.parse_args()

def handle_error(url, save_path=None):
    """Log failed file URLs to centralized log"""
    global GLOBAL_LOG_PATH
    if GLOBAL_LOG_PATH is None:
        return
    
    try:
        os.makedirs(os.path.dirname(GLOBAL_LOG_PATH), exist_ok=True)
        with open(GLOBAL_LOG_PATH, 'a') as log_file:
            log_file.write(f"{url}\n")
    except Exception as e:
        print(f"[LOGGING ERROR] Could not write to lost file list: {e}")

def download_file(url, save_path, dry_run=False, force=False):
    filename = os.path.basename(urlparse(url).path)
    full_save_path = save_path if save_path.endswith(filename) else os.path.join(save_path, filename)

    if os.path.isfile(full_save_path):
        if dry_run:
            if not force:
                print(f"[SKIP] {full_save_path} already exists")
                return
            else:
                print(f"[DRY-RUN][OVERWRITE] {full_save_path} from {url}")
                return
        if not force:
            print(f"[SKIP] {full_save_path} already exists")
            return
        else:
            print(f"[OVERWRITE] {full_save_path} exists but force=True")
    elif dry_run:
        print(f"[DRY-RUN] Would save: {full_save_path} from {url}")
        return

    try:
        if not os.path.exists(os.path.dirname(save_path)):
            os.makedirs(os.path.dirname(save_path))
        print(f"[DOWNLOADING] {url}")
        r = requests.get(url, headers=HEADERS, stream=True, timeout=15)
        r.raise_for_status()
        with open(full_save_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f"[SAVED] {full_save_path}")
    except requests.exceptions.Timeout as e:
        print(f"[Timeout ERROR] Failed to download {url}: {e}")
        handle_error(url)
    except requests.exceptions.RequestException as e:
        print(f"[Request ERROR] Failed to download {url}: {e}")
        handle_error(url)
    except Exception as e:
        print(f"[ERROR] Failed to download {url}: {e}")
        handle_error(url)

def fix_lost_downloads(dry_run=False, force=False, root="/media/X/NOAA"):
    basedir = f"{root}/bak_log"
    path_map = load_fallback_mappings()
    for fname in os.listdir(basedir):
        if fname.startswith("data_lost_filelist") and fname.endswith(".log"):
            with open(os.path.join(basedir, fname)) as f:
                for line in f:
                    url = line.strip()
                    if not url:
                        continue
                    matched = False
                    for base_url in path_map:
                        if url.startswith(base_url):
                            relative_path = url[len(base_url):].lstrip('/')
                            save_path = os.path.join(path_map[base_url], relative_path)
                            download_file(url, save_path, dry_run=dry_run, force=force)
                            matched = True
                            break
                    if not matched:
                        path_after = url.split("/thredds-ocean/fileServer/")[-1]
                        parts = path_after.split("/")     # e.g. ['ndbc','tao-buoy','2015','02','file.nc']
                        save_dir = os.path.join(root, *parts[:-1])
                        download_file(url, save_dir, dry_run=dry_run, force=force)

def is_year_directory(dirname):
    """Check if directory name is a 4-digit year"""
    return re.match(r'^\d{4}$', dirname) is not None

def should_skip_year_dir(dirname):
    """Check if we should skip this year directory based on MIN_YEAR filter"""
    global MIN_YEAR
    if MIN_YEAR is None:
        return False
    
    if is_year_directory(dirname):
        try:
            year = int(dirname)
            if year < MIN_YEAR:
                print(f"[SKIP YEAR] Skipping year {year} (< {MIN_YEAR})")
                return True
        except ValueError:
            pass
    return False

def crawl_http_directory(base_url, save_root, file_type_filter=None, dry_run=False, force=False):
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
                dirname = href.strip('/')
                
                # Check if we should skip this year directory
                if should_skip_year_dir(dirname):
                    continue
                    
                subdir = os.path.join(save_root, dirname)
                crawl_http_directory(full_url, subdir, file_type_filter, dry_run, force)
            else:
                if file_type_filter and not any(href.endswith(ext) for ext in file_type_filter):
                    continue
                rel_path = os.path.relpath(full_url, start=base_url).split('?')[0]
                save_path = os.path.join(save_root, rel_path)
                download_file(full_url, save_path, dry_run=dry_run, force=force)
    except Exception as e:
        print(f"[ERROR] Failed to crawl {base_url}: {e}")
        # Don't log directory crawl failures - we only want to log individual file failures
        # The individual file download failures will be logged by download_file() -> handle_error()

def load_fallback_mappings():
    path_map = {}
    config_file = "/media/X/NOAA/bak_log/fix_path.txt"
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            for line in f:
                parts = line.strip().split(',')
                if len(parts) == 2:
                    base, target = parts
                    path_map[base.strip()] = target.strip()
    return path_map

def append_to_fix_path(base_url, outdir):
    config_file = "/media/X/NOAA/bak_log/fix_path.txt"
    new_entry = f"{base_url.rstrip('/')},{outdir.rstrip('/')}"
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            lines = {line.strip() for line in f if line.strip()}
        if new_entry in lines:
            return  # Prevent duplicates
    with open(config_file, 'a') as f:
        f.write(new_entry + "\n")

def main():
    global GLOBAL_LOG_PATH, MIN_YEAR
    args = parse_args()

    # Parse year filter if provided
    if args.year:
        try:
            MIN_YEAR = int(args.year)
            print(f"[INFO] Will skip years before {MIN_YEAR}")
        except ValueError:
            print(f"[ERROR] Invalid year format: {args.year}. Please use 4-digit year (e.g., 2007)")
            sys.exit(1)

    if args.fix:
        fix_lost_downloads(dry_run=args.dry_run, force=args.force,
                           root="d:/backup/NOAA" if platform.system() == "Windows" else "/media/X/NOAA")
        return

    if args.fallback:
        outdir = args.outdir or os.path.join("/media/X/NOAA", args.database if args.database else "")
        # Set up centralized log path for fallback mode
        GLOBAL_LOG_PATH = os.path.join(outdir, "data_lost_filelist.log")
        print(f"[INFO] Centralized error log will be at: {GLOBAL_LOG_PATH}")
        print("[INFO] Falling back to direct HTTP directory crawling mode...")
        crawl_http_directory(args.fallback, outdir, file_type_filter=[f".{args.type}"] if args.type else None,
                             dry_run=args.dry_run, force=args.force)
        return

    # standard mode
    if not args.database or not args.data:
        print("[ERROR] --database and --data are required unless using --fix or --fallback")
        return

    database = args.database.strip("/")
    dataset = args.data.strip("/")

    db_info = DATABASES.get(database)
    if not db_info:
        print(f"[ERROR] Unknown database: {database}")
        sys.exit(1)

    savedir = "d:/backup/NOAA" if platform.system() == "Windows" else "/media/X/NOAA"
    save_root = os.path.join(savedir, database, dataset)
    
    # Set up centralized log path for standard mode
    GLOBAL_LOG_PATH = os.path.join(save_root, "data_lost_filelist.log")
    print(f"[INFO] Centralized error log will be at: {GLOBAL_LOG_PATH}")

    file_type_filter = [f".{ext.strip()}" for ext in args.type.split(",")] if args.type else None

    base_fileserver_url = f"{db_info['BASE_FILESERVER_URL']}/{dataset}"
    catalog_root_url = f"{db_info['BASE_CATALOG_URL']}/{dataset}"
    base_http_url = f"{db_info['BASE_HTTP_URL']}/{dataset}/"

    try:
        test_catalog = f"{catalog_root_url}/catalog.html"
        r = requests.head(test_catalog, timeout=5)
        r.raise_for_status()
        crawl_http_directory(base_fileserver_url, save_root, file_type_filter=file_type_filter,
                             dry_run=args.dry_run, force=args.force)
    except Exception:
        print("[INFO] Falling back to direct HTTP directory crawling mode...")
        crawl_http_directory(base_http_url, save_root, file_type_filter=file_type_filter,
                             dry_run=args.dry_run, force=args.force)

if __name__ == "__main__":
    main()