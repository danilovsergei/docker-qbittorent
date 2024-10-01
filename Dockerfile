FROM alpine:latest AS builder

# Install git and dependencies
RUN apk add --no-cache git make cmake g++ boost-dev openssl-dev qt6-qttools-dev

# Download libtorrent and qBittorrent
RUN git clone https://github.com/qbittorrent/qBittorrent.git
RUN git clone --recursive https://github.com/arvidn/libtorrent.git

# Build and install libtorrent
RUN cd libtorrent && \
    cmake -DCMAKE_INSTALL_LIBDIR=lib . && \
    make -j`nproc` && \
    make install && \
    strip /usr/local/lib/libtorrent-rasterbar.so.2.0

# Build and install qBittorrent
RUN cd qBittorrent && \
    cmake -B build -DCMAKE_BUILD_TYPE=Release -DGUI=OFF && \
    cmake --build build && \
    cmake --install build

RUN cd qBittorrent && \
    apk add --no-cache qt6-qttools-dev && \
    cmake -B build -DCMAKE_BUILD_TYPE=Release -DGUI=OFF && \
    cmake --build build && \
    cmake --install build

FROM alpine:latest

COPY --from=builder /usr/local/lib/libtorrent-rasterbar.so.2.0 /usr/lib/libtorrent-rasterbar.so.2.0

COPY --from=builder /usr/local/bin/qbittorrent-nox /usr/bin/qbittorrent-nox

COPY entrypoint.sh /entrypoint.sh

RUN apk add --no-cache qt6-qtbase qt6-qtsvg shadow tzdata

ENV TZ=America/Los_Angeles

ENV WEBUI_PORT="8080" CHUID=1000 CHGID=1000

EXPOSE 6881 6881/udp 8080

ENTRYPOINT ["/entrypoint.sh"]
