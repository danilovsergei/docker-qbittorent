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

```bash
/usr/bin/docker run --rm --name qbittorrent --mount type=bind,source=/home/qbittorrent,target=/home/qbittorrent --mount type=bind,source=/Storage,target=/Storage -e WEBUI_PORT=8080 -e CHUID=1000 -e CHGID=1000 -p 6881:6881 -p 6881:6881/udp -p 8080:8080 geonix/qbittorrent:latest
```

# Usage
Qbittorrent will listen on <your_host>:8080 port 

# Update docker image
To update existing docker image run 
```bash
docker pull geonix/qbittorrent:latest && \
systemctl restart qbittorrent
```

# Bundled Glider Proxy & High Availability

The main benefit of bundling [glider](https://github.com/danilovsergei/glider) into this image is to allow load balancing and automatically switching to the best proxy on the fly without restarting qBittorrent. Our forked version of glider also includes a patch that fixes SOCKS5 UDP Associate bugs, allowing DHT to work seamlessly through upstream proxies.

To enable the proxy, you must pass the `-e ENABLE_GLIDER=true` environment variable and mount your `glider.conf` configuration file to `/etc/glider/glider.conf`.

```bash
docker run -d --name qbittorrent \
  --mount type=bind,source=/home/qbittorrent,target=/home/qbittorrent \
  --mount type=bind,source=/Storage,target=/Storage \
  --mount type=bind,source=/path/to/your/glider.conf,target=/etc/glider/glider.conf \
  -e ENABLE_GLIDER=true \
  -e WEBUI_PORT=8080 -e CHUID=1000 -e CHGID=1000 \
  -p 6881:6881 -p 6881:6881/udp -p 8080:8080 \
  geonix/qbittorrent:latest
```

## Configuring qBittorrent to use Glider

When `glider` is enabled, it automatically runs inside the container and binds to `127.0.0.1:1081`. 

**You MUST configure your qBittorrent Connection settings as follows via the WebUI:**
- **Proxy Type:** SOCKS5
- **Host:** `127.0.0.1`
- **Port:** `1081`
- **Authentication:** Unchecked / Disabled
- **Use proxy for peer connections:** Checked

## Example glider.conf for Load Balancing

Below is an example `glider.conf` that load-balances multiple upstream proxy servers based on connection latency (LHA) while automatically avoiding failing connections:

```ini
verbose=True
# Local listener for qBittorrent to connect to (Do not change)
listen=socks5://0.0.0.0:1081

# High availability strategy: "lha" (Latency-based High Availability)
strategy=lha

# Health check interval and timeout (in seconds)
checkinterval=30
checktimeout=10
# Health check target: test TCP connectivity to Google
check=tcp://www.google.com:80

# Maximum failures before marking an upstream proxy as DISABLED
maxfailures=2

# Upstream proxy pool
forward=socks5://user:pass@89.47.234.26:1080
forward=socks5://user:pass@89.47.234.27:1080
forward=socks5://user:pass@89.47.234.28:1080
forward=socks5://user:pass@89.47.234.29:1080
```
