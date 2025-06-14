#!/bin/bash

# === Usage: sudo ./lftp_ndbc_monthly.sh 201001 202312 ===
START_MONTH="$1"
END_MONTH="$2"

if [[ -z "$START_MONTH" || -z "$END_MONTH" ]]; then
    echo "\n❌ Usage: sudo $0 <START_YYYYMM> <END_YYYYMM>"
    exit 1
fi

FTP_HOST="ftp-oceans.ncei.noaa.gov"
REMOTE_BASE="/pub/data.nodc/ndbc/hfradar/radial"
LOCAL_BASE="/media/X/NOAA/ndbc/hfradar/radial"

# === Helper: increment YYYYMM safely ===
function increment_month() {
    local yymm="$1"
    # append day 01, shift 1 month, output YYYYMM again (UTC to avoid locale surprises)
    date -u -d "${yymm}01 +1 month" +"%Y%m"
}

CUR_MONTH="$START_MONTH"

while [[ "$CUR_MONTH" -le "$END_MONTH" ]]; do
    YEAR="${CUR_MONTH:0:4}"
    MONTH="${CUR_MONTH:4:2}"
    SUBDIR="${YEAR}${MONTH}"
    REMOTE_DIR="${REMOTE_BASE}/${YEAR}/${SUBDIR}"
    LOCAL_DIR="${LOCAL_BASE}/${YEAR}/${SUBDIR}"

    echo -e "\n📦 Syncing $REMOTE_DIR -> $LOCAL_DIR"

    # Ensure local directory exists
    sudo mkdir -p "$LOCAL_DIR"

    # Run lftp mirror as sudo (due to NAS restrictions)
    sudo lftp "$FTP_HOST" -e "\
        set ftp:list-options -a; \
        set net:max-retries 3; \
        set net:timeout 20; \
        mirror --no-symlinks --only-newer --parallel=4 $REMOTE_DIR $LOCAL_DIR; \
        quit"

    echo "✅ Completed: $SUBDIR"
    CUR_MONTH=$(increment_month "$CUR_MONTH")
done

echo -e "\n🎉 All months from $START_MONTH to $END_MONTH processed successfully!"
