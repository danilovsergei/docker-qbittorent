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

target_dir="$home_dir/qBittorrent"
if [ -d "$target_dir" ]; then
    echo "[INFO] Checking for stale IPC frameworks..."
    if [ -f "$target_dir/lockfile" ] || [ -f "$target_dir/ipc-socket" ]; then
        echo "[WARNING] Stale lockfile or IPC socket detected. Clearing communication channel."
        chown -R $CHUID:$CHGID "$target_dir"
        rm -f "$target_dir/lockfile"
        rm -f "$target_dir/ipc-socket"
    fi
fi

if [ "$ENABLE_GLIDER" = "true" ] || [ "$ENABLE_GLIDER" = "1" ]; then
    if [ -f "/etc/glider/glider.conf" ]; then
    echo "[INFO] Starting bundled glider proxy..."
    /usr/bin/glider -config /etc/glider/glider.conf &
else
        echo "[WARNING] ENABLE_GLIDER is true, but /etc/glider/glider.conf not found. Bundled proxy will not start."
    fi
else
    echo "[INFO] Glider proxy is disabled (ENABLE_GLIDER is not true)."

fi

umask 0000
su qbittorrent << INNEREOF
HOME="$home_dir" XDG_CONFIG_HOME="$home_dir" XDG_DATA_HOME="$home_dir" qbittorrent-nox --confirm-legal-notice --webui-port=$WEBUI_PORT
INNEREOF
