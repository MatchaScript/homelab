ARG BOOTC_BASE
FROM ${BOOTC_BASE} AS builder
# https://gitlab.com/fedora/bootc/base-images/-/issues/49
ARG TARGETARCH='arm64'
COPY overlay.d/99-asahi-builder/ /
COPY overlay.d/01-common/ /
RUN dnf install -y --setopt=install_weak_deps=False \
    --setopt=tsflags=nodocs \
    dnf5-plugins
RUN dnf copr enable -y @asahi/fedora-remix-branding
RUN dnf install -y asahi-repos
# replace kernel to kernel-16k /usr/share/doc/bootc-base-imagectl/manifests/minimal/kernel.yaml
RUN sed -i 's/kernel/kernel-16k/g' /usr/share/doc/bootc-base-imagectl/manifests/minimal/kernel.yaml
RUN /usr/libexec/bootc-base-imagectl build-rootfs --manifest=asahi /target-rootfs
RUN mkdir -p /target-rootfs/usr/lib/selinux/targeted && \
    mv /target-rootfs/etc/selinux/targeted/active /target-rootfs/usr/lib/selinux/targeted/ && \
    mv /target-rootfs/etc/selinux/final /target-rootfs/usr/lib/selinux/ && \
    sed -i 's|^store-root=/etc/selinux$|store-root=/usr/lib/selinux|' /target-rootfs/etc/selinux/semanage.conf && \
    test "$(grep -c '^store-root=' /target-rootfs/etc/selinux/semanage.conf)" = 1 && \
    grep -q '^store-root=/usr/lib/selinux$' /target-rootfs/etc/selinux/semanage.conf

FROM scratch
ARG VERSION_ID
COPY --from=builder /target-rootfs/ /
COPY overlay.d/01-common/ /
COPY overlay.d/01-growpart/ /
COPY overlay.d/50-asahi/ /
RUN dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs cloud-utils-growpart
RUN <<EOF
bash /opt/bin/update-m1n1-bootc.sh
dnf clean all && rm -rf /var/cache/dnf
bootc container lint
EOF

LABEL containers.bootc=1
LABEL ostree.bootable=1
LABEL org.opencontainers.image.title="asahi-bootc"
LABEL org.opencontainers.image.description="Fedora Asahi bootc base image for Apple Silicon (arm64) homelab nodes"
LABEL org.opencontainers.image.version="${VERSION_ID}"
LABEL org.opencontainers.image.source="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.url="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.documentation="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.vendor="MatchaScript"
LABEL org.opencontainers.image.base.name="quay.io/fedora/fedora-bootc:latest"

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
