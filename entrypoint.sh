#!/bin/sh

cp /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
echo "Set Time-Zone to Los Angeles PCT"
now=$(date)
echo "Current date: $now"
home_dir="/home/qbittorrent"

if ! id qbittorrent; then
    echo "[WARNING] User not found. Maybe first bootstrap?"
    echo "[INFO] Try to create user qbittorrent."
    groupadd -g $CHGID -o qbittorrent
    useradd -d $home_dir -u $CHUID -g $CHGID -o qbittorrent
    if [ -d $home_dir ]; then
        echo "[INFO] Try to fix home folder permissions."
        chown -R $CHUID:$CHGID $home_dir
    fi
    echo "[INFO] User qbittorrent($CHUID:$CHGID) created with home folder $home_dir"
fi

if [ -f $home_dir/qBittorrent/qBittorrent.conf ]; then
    chown $CHUID:$CHGID $home_dir/qBittorrent/qBittorrent.conf
else
    echo "Error $home_dir/qBittorrent/qBittorrent.conf is not provided"
fi

# =====================================================================
# STALE LOCK CLEANUP FOR QLOCKFILE
# =====================================================================
# Qt's QLockFile causes an early exit if a stale lock file or socket
# remains from an ungraceful container shutdown.
# =====================================================================
target_dir="$home_dir/qBittorrent"
if [ -d "$target_dir" ]; then
    echo "[INFO] Checking for stale IPC frameworks..."

    if [ -f "$target_dir/lockfile" ] || [ -f "$target_dir/ipc-socket" ]; then
        echo "[WARNING] Stale lockfile or IPC socket detected. Clearing communication channel."

        # Ensure root can remove them regardless of past ownership mismatches
        chown -R $CHUID:$CHGID "$target_dir"

        rm -f "$target_dir/lockfile"
        rm -f "$target_dir/ipc-socket"
    fi
fi

# qbittorrent will create files by default with read and write permissions for everyone
umask 0000
su qbittorrent << EOF
HOME="$home_dir" XDG_CONFIG_HOME="$home_dir" XDG_DATA_HOME="$home_dir" qbittorrent-nox --confirm-legal-notice --webui-port=$WEBUI_PORT
EOF
