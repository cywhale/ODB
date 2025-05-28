#!/bin/bash

# === Usage: ./lftp_ndbc.sh 2014 ===
YEAR="$1"
if [[ -z "$YEAR" ]]; then
    echo "❌ Please specify a year. Usage: $0 <YEAR>"
    exit 1
fi

# === Configuration ===
FTP_HOST="ftp-oceans.ncei.noaa.gov"
REMOTE_BASE="/pub/data.nodc/ndbc/hfradar/radial/${YEAR}"
LOCAL_BASE="/media/X/NOAA/ndbc/hfradar/radial/${YEAR}"

# === Prompt sudo once ===
echo "🔐 Requesting sudo access (for /media/X/...):"
sudo -v || { echo "❌ Sudo failed"; exit 1; }

# === Create base directory if missing ===
if ! sudo test -d "$LOCAL_BASE"; then
    echo "📁 Creating local base directory: $LOCAL_BASE"
    sudo mkdir -p "$LOCAL_BASE"
fi

# === Loop through all months ===
for month in {01..12}; do
    SUBDIR="${YEAR}${month}"
    REMOTE_DIR="${REMOTE_BASE}/${SUBDIR}"
    LOCAL_DIR="${LOCAL_BASE}/${SUBDIR}"

    # Create local subdirectory if not exists
    if ! sudo test -d "$LOCAL_DIR"; then
        echo "📁 Creating subdirectory: $LOCAL_DIR"
        sudo mkdir -p "$LOCAL_DIR"
    else
        echo "📂 Subdirectory exists: $LOCAL_DIR — continuing with mirror"
    fi

    echo "==> 🔄 Syncing ${REMOTE_DIR} to ${LOCAL_DIR}..."

    # Use lftp mirror even if local folder exists (to resume partial downloads)
    sudo lftp "$FTP_HOST" <<EOF
set ftp:list-options -a
set net:max-retries 3
set net:timeout 20
mirror --no-symlinks --only-newer --parallel=4 ${REMOTE_DIR} ${LOCAL_DIR}
quit
EOF

    echo "✅ Finished syncing ${SUBDIR}"
done

echo "🎉 All months in ${YEAR} processed successfully!"
