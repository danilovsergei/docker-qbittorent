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
/usr/bin/docker run --rm --name qbittorrent \
  --mount type=bind,source=/home/qbittorrent,target=/home/qbittorrent \
  --mount type=bind,source=/Storage,target=/Storage \
  --mount type=bind,source=/etc/glider/glider.conf,target=/etc/glider/glider.conf,readonly \
  -e ENABLE_GLIDER=true \
  -e WEBUI_PORT=8080 -e CHUID=1000 -e CHGID=1000 \
  -p 6881:6881 -p 6881:6881/udp -p 8080:8080 \
  geonix/qbittorrent:latest
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

# Maximum failures before marking an upstream proxy as DISABLED.
# IMPORTANT: For BitTorrent traffic, set maxfailures=0. BitTorrent swarms dial hundreds of offline peers
# and unsupported IPv6 addresses; if maxfailures > 0, normal peer connection timeouts will quickly disable
# all healthy proxies in the pool. With maxfailures=0, forwarders are only disabled when the health check itself fails.
maxfailures=0

# Upstream proxy pool
forward=socks5://user:pass@89.47.234.26:1080
forward=socks5://user:pass@89.47.234.27:1080
forward=socks5://user:pass@89.47.234.28:1080
forward=socks5://user:pass@89.47.234.29:1080
```

# Troubleshooting & Glider Logs

When Glider is enabled, it runs in the background inside the container and emits logs directly to the container's standard output.

## Quick Verification Commands

### 1. Test Proxy Connectivity & Fetch Current Exit IP
Run `curl` through the local SOCKS5 proxy to verify end-to-end traffic routing and see which upstream proxy IP is currently active:
```bash
docker exec qbittorrent curl -s -m 10 -x socks5h://127.0.0.1:1081 https://api.ipify.org
```
* **Expected Output**: A remote proxy IP address from your pool (e.g. `146.70.27.218`).
* If this command prints an external IP, **Glider is 100% working and routing traffic**.

### 2. Fast Port Listener Check
Verify that Glider's local SOCKS5 port is open and listening (uses built-in `nc`):
```bash
docker exec qbittorrent nc -zv 127.0.0.1 1081
```
* **Expected Output**: `127.0.0.1 (127.0.0.1:1081) open`
* If it returns `Connection refused`, Glider is not running inside the container.

## Viewing Logs

To view real-time logs from both qBittorrent and Glider:
```bash
docker logs -f qbittorrent
```

To filter specifically for Glider health checks, proxy status, and peer connections:
```bash
docker logs qbittorrent 2>&1 | grep -E "(group|forwarder|socks5|check)"
```

## Common Issues & Error Examples

### 1. `[INFO] Glider proxy is disabled` (Port 1081 Connection Refused)
* **Log Signature**:
  ```text
  [INFO] Glider proxy is disabled (ENABLE_GLIDER is not true).
  ```
* **Symptom**:
  qBittorrent fails to connect to `127.0.0.1:1081`. All torrents show 0 peers and 0 KB/s download speed.
* **Cause**:
  The container was started without `-e ENABLE_GLIDER=true` and without `/etc/glider/glider.conf` mounted.
* **Fix**:
  Ensure your `docker run` or `systemd/qbittorrent.service` includes:
  ```bash
  --mount type=bind,source="/etc/glider/glider.conf",target=/etc/glider/glider.conf,readonly \
  -e ENABLE_GLIDER=true
  ```

---

### 2. Cascading Proxy Pool Disablement (`maxfailures > 0`)
* **Log Signature**:
  ```text
  server.go:86: [socks5] 127.0.0.1:52958 <-> [2a00:1e88:4c5b:700:5d0f:359e:392d:885b]:51413 via 89.47.234.28:1080, error in dial: proxy: SOCKS5 proxy at 89.47.234.28:1080 failed to connect: address type not supported
  forward.go:140: [forwarder] 89.47.234.28:1080(0) reaches maxfailures: 2
  group.go:179: [group] main: 89.47.234.28:1080(0) changed status from ENABLED to DISABLED (0 of 56 currently enabled)
  ```
* **Symptom**:
  qBittorrent works for 1–2 minutes after restart, then all downloads permanently freeze. Glider logs show `0 of N currently enabled`.
* **Cause**:
  BitTorrent swarms connect to hundreds of random peers. Many peers are offline, closed-port, or advertise IPv6 addresses (which IPv4 SOCKS5 proxies reject with `address type not supported`).
  When `maxfailures > 0` (e.g. `maxfailures=2`), Glider mistakenly treats these unreachable remote peer IPs as upstream proxy outages and disables the entire proxy pool.
* **Fix**:
  In `/etc/glider/glider.conf`, set:
  ```ini
  maxfailures=0
  ```
  With `maxfailures=0`, peer dial errors are ignored, and proxy health is exclusively managed by the periodic health check (`check=tcp://www.google.com:80`, `checkinterval=30`).

---

### 3. Normal Successful Glider Traffic
When everything is working normally, you will see code `91` logs indicating active data relay through the upstream proxy pool:
```text
server.go:91: [socks5] 127.0.0.1:40928 <-> 62.217.187.185:43745 via 89.47.234.27:1080
server.go:91: [socks5] 127.0.0.1:51848 <-> 176.106.242.101:18943 via 89.47.234.27:1080
```
