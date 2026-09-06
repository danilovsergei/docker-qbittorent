FROM alpine:latest AS builder

# Install build dependencies
RUN apk add --no-cache git make cmake g++ boost-dev openssl-dev qt6-qtbase-dev qt6-qttools-dev qt6-qtbase-private-dev

# Clone and build libtorrent pinned to 2.0 release branch
RUN git clone --recursive https://github.com/arvidn/libtorrent.git && \
    cd libtorrent && \
    cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_LIBDIR=lib && \
    cmake --build build --parallel $(nproc) && \
    cmake --install build && \
    strip /usr/local/lib/libtorrent-rasterbar.so*

# Clone and build qBittorrent
RUN git clone https://github.com/qbittorrent/qBittorrent.git && \
    cd qBittorrent && \
    cmake -B build -DCMAKE_BUILD_TYPE=Release -DGUI=OFF && \
    cmake --build build --parallel $(nproc) && \
    cmake --install build

# Final runtime image
FROM alpine:latest

# Copy built shared libraries and binary
COPY --from=builder /usr/local/lib/libtorrent-rasterbar.so* /usr/lib/
COPY --from=builder /usr/local/bin/qbittorrent-nox /usr/bin/qbittorrent-nox

# Install runtime dependencies
RUN apk add --no-cache qt6-qtbase qt6-qtsvg shadow tzdata libgcc libstdc++ boost-system

COPY entrypoint.sh /entrypoint.sh

ENV TZ=America/Los_Angeles
ENV WEBUI_PORT="8080" CHUID=1000 CHGID=1000

EXPOSE 6881 6881/udp 8080

ENTRYPOINT ["/entrypoint.sh"]
