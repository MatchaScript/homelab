ARG BOOTC_BASE
FROM ${BOOTC_BASE} AS builder
ARG TARGETARCH='amd64'

RUN /usr/libexec/bootc-base-imagectl build-rootfs --manifest=fedora-minimal /target-rootfs
FROM scratch
ARG VERSION_ID
COPY --from=builder /target-rootfs/ /
COPY overlay.d/01-common/ /
RUN <<EOF
set -xeuo pipefail
dnf clean all && rm -rf /var/cache/dnf
bootc container lint
EOF
LABEL containers.bootc=1
LABEL ostree.bootable=1
LABEL org.opencontainers.image.title="fedora-bootc"
LABEL org.opencontainers.image.description="Fedora bootc base image for a homelab cluster"
LABEL org.opencontainers.image.version="${VERSION_ID}"
LABEL org.opencontainers.image.source="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.url="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.documentation="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.vendor="MatchaScript"
LABEL org.opencontainers.image.base.name="quay.io/fedora/fedora-bootc:latest"

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
