# Description
Docker image with latest qbittorrent from git

Creates image with two tags: latest and buld date, eg. 09_30_2024


# Execution
Docker image requires to mount two directories. One for downloads and another to keep qbittorrent config.\
My config assumes:
* You have a system `/Storage` directory. It will be mount to Qbittorrent docker container with the same name. So specifying '/Storage' as downloads folder while downloading torrent will work

* There is a system `/home/qbittorrent`. It will be mount to `/home/qbittorrent` local docker folder. This folder is used to keep qbittorrent settings.

## With systemd
It's expected to run it with systemd service. Here is service file in systemd folder

## Command line
Here is a dump of command line what systemd runs:



```
/usr/bin/docker run --rm --name qbittorrent --mount type=bind,source=/home/qbittorrent,target=/home/qbittorrent --mount type=bind,source=/Storage,target=/Storage -e WEBUI_PORT=8080 -e CHUID=1000 -e CHGID=1000 -p 6881:6881 -p 6881:6881/udp -p 8080:8080 geonix/qbittorrent:latest
```

# Usage
Qbittorrent will listen on <your_host>:8080 port 