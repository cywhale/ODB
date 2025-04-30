import os
import time
import requests
from bs4 import BeautifulSoup

BASE_URL = "https://www.ncei.noaa.gov/products/estuarine-bathymetric-digital-elevation-models"
SAVE_DIR = "/media/X/NOAA/ncei/estuarine_bathymetry"
USER_AGENT = {"User-Agent": "Mozilla/5.0"}

def ensure_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

def fetch_html(url):
    response = requests.get(url, headers=USER_AGENT, timeout=15)
    response.raise_for_status()
    return response.text

def convert_nc_catalog_url(url):
    if "dataset=" in url:
        filename = url.split("dataset=")[-1].split("/")[-1]
        return f"https://www.ngdc.noaa.gov/thredds/fileServer/regional/{filename}"
    return None

def download_file(url, save_path):
    if os.path.exists(save_path):
        print(f"[SKIP] {os.path.basename(save_path)} already exists")
        return
    try:
        print(f"[DOWNLOADING] {url}")
        r = requests.get(url, headers=USER_AGENT, stream=True, timeout=15)
        r.raise_for_status()
        with open(save_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f"[SAVED] {save_path}")
    except Exception as e:
        print(f"[ERROR] Failed to download {url}: {e}")
        with open(os.path.join(SAVE_DIR, "data_lost_filelist_estuarine.log"), 'a') as log_file:
            log_file.write(f"{url}\n")

def parse_table_and_download():
    ensure_dir(SAVE_DIR)
    html = fetch_html(BASE_URL)
    soup = BeautifulSoup(html, "lxml")
    table = soup.find("table")
    rows = table.find_all("tr")

    for row in rows:
        cols = row.find_all("td")
        if len(cols) != 3:
            continue

        location = cols[0].text.strip().replace(" ", "_")
        nc_link_tag = cols[1].find("a", href=True)
        xml_link_tag = cols[2].find("a", href=True)

        if not nc_link_tag or not xml_link_tag:
            continue

        nc_url = convert_nc_catalog_url(nc_link_tag["href"])
        xml_url = xml_link_tag["href"]

        if nc_url:
            nc_path = os.path.join(SAVE_DIR, f"{location}.nc")
            download_file(nc_url, nc_path)
            time.sleep(0.5)

        if xml_url:
            xml_path = os.path.join(SAVE_DIR, f"{location}.xml")
            download_file(xml_url, xml_path)
            time.sleep(0.5)

def main():
    print("[START] Downloading estuarine bathymetric DEMs and metadata...")
    parse_table_and_download()
    print("[DONE] All available files processed.")

if __name__ == "__main__":
    main()
