ARG SYSBASE
FROM ${SYSBASE} AS system-build
RUN --mount=type=cache,target=/var/cache/dnf \
    source /etc/os-release; \
    mkdir -p /mnt/sys-root; \
    dnf install --installroot /mnt/sys-root \
    --releasever ${VERSION_ID} --setopt install_weak_deps=false --nodocs --use-host-config -y \
    gcc \
    glibc-devel \
    kernel-headers \
    libgcc \
    libstdc++-devel;
RUN dnf --installroot /mnt/sys-root clean all; \
    rm -rf /mnt/sys-root/var /mnt/sys-root/usr/lib/sysimage /mnt/sys-root/usr/share/locale

FROM scratch
ARG VERSION_ID
LABEL org.opencontainers.image.title="fedora-sysroot"
LABEL org.opencontainers.image.description="Fedora sysroot (glibc and gcc runtime headers and libraries) for cross-compiling to a homelab cluster"
LABEL org.opencontainers.image.version=${VERSION_ID}
LABEL org.opencontainers.image.source="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.url="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.documentation="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.vendor="MatchaScript"
LABEL org.opencontainers.image.base.name="quay.io/fedora/fedora:latest"
COPY --from=system-build /mnt/sys-root/ /
