ARG SYSBASE

FROM ghcr.io/matchascript/fedora:latest AS builder

RUN dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
    rust cargo git
RUN git clone --depth 1 https://github.com/AsahiLinux/tuxvdmtool /tmp/tuxvdmtool-src && \
    cd /tmp/tuxvdmtool-src && cargo build --release && \
    /tmp/tuxvdmtool-src/target/release/tuxvdmtool --version

# Stage 2: Main bootc image
FROM ${SYSBASE}

COPY --from=builder /tmp/tuxvdmtool-src/target/release/tuxvdmtool /usr/local/bin/tuxvdmtool
RUN chmod 0755 /usr/local/bin/tuxvdmtool && tuxvdmtool --version

RUN <<EOF
dnf install i2c-tools pciutils usbutils tar @development-tools \
    util-linux trace-cmd bpftrace uv git
dnf clean all && rm -rf /var/cache/dnf
bootc container lint
EOF
