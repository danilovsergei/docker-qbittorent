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

# qbittorrent will create files by defaul with read and write permissions for everyone
umask 0000
su qbittorrent << EOF
HOME="$home_dir" XDG_CONFIG_HOME="$home_dir" XDG_DATA_HOME="$home_dir" qbittorrent-nox --webui-port=$WEBUI_PORT
EOF
