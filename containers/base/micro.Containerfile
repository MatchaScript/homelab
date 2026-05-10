ARG SYSBASE=quay.io/fedora/fedora:latest@sha256:cf44ad589742ddc8a05a4a655fcd17f42b378dd202eff925dfd54ce1a37ce76f
FROM ${SYSBASE} AS system-build
RUN --mount=type=cache,target=/var/cache/dnf \
    source /etc/os-release; \
    mkdir -p /mnt/sys-root; \
    echo ${VERSION_ID}; \
    dnf install --installroot /mnt/sys-root \
    --releasever ${VERSION_ID} --setopt install_weak_deps=false --nodocs --use-host-config -y \
    coreutils-single \
    glibc-minimal-langpack;
RUN dnf --installroot /mnt/sys-root clean all;

# Additional hacks for kickstart file and backward compatable support
RUN rm -rf /mnt/sys-root/var/cache/dnf /mnt/sys-root/var/log/dnf* /mnt/sys-root/var/lib/dnf /mnt/sys-root/var/log/yum.* /mnt/sys-root/var/lib/rpm/* ; \
    /bin/date +%Y%m%d_%H%M > /mnt/sys-root/etc/BUILDTIME ;  \
    echo '%_install_langs C.utf8' > /mnt/sys-root/etc/rpm/macros.image-language-conf; \
    echo 'LANG="C.utf8"' >  /mnt/sys-root/etc/locale.conf; \
    echo 'container' > /mnt/sys-root/etc/dnf/vars/infra; \
    rm -f /mnt/sys-root/etc/machine-id; \
    touch /mnt/sys-root/etc/machine-id; \
    touch /mnt/sys-root/etc/resolv.conf; \
    touch /mnt/sys-root/etc/hostname; \
    touch /mnt/sys-root/etc/.pwd.lock; \
    chmod 600 /mnt/sys-root/etc/.pwd.lock; \
    rm -rf /mnt/sys-root/usr/share/locale/en* /mnt/sys-root/boot /mnt/sys-root/dev/null /mnt/sys-root/var/log/hawkey.log ; \
    echo '0.0 0 0.0' > /mnt/sys-root/etc/adjtime; \
    echo '0' >> /mnt/sys-root/etc/adjtime; \
    echo 'UTC' >> /mnt/sys-root/etc/adjtime; \
    echo 'KEYMAP="us"' > /mnt/sys-root/etc/vconsole.conf; \
    echo 'FONT="eurlatgr"' >> /mnt/sys-root/etc/vconsole.conf; \
    mkdir -p /mnt/sys-root/run/lock; \
    cd /mnt/sys-root/etc ; \
    ln -s ../usr/share/zoneinfo/UTC localtime

FROM scratch
ARG VERSION_ID
LABEL org.opencontainers.image.title="fedora-micro"
LABEL org.opencontainers.image.description="Ultra-minimal Fedora userspace image (micro variant) for the fjord homelab"
LABEL org.opencontainers.image.version=${VERSION_ID}
LABEL org.opencontainers.image.source="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.url="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.documentation="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.vendor="MatchaScript"
LABEL org.opencontainers.image.base.name="quay.io/fedora/fedora:latest"
COPY --from=system-build /mnt/sys-root/ /

CMD /bin/sh