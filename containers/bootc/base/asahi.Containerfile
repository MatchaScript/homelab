FROM quay.io/fedora/fedora-bootc:latest@sha256:7808df8be42453623448669e80e762adfe2ff6d74b26505d610d16acfadb6b98 AS builder
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

FROM scratch
ARG VERSION_ID
COPY --from=builder /target-rootfs/ /
COPY overlay.d/01-common/ /
COPY overlay.d/50-asahi/ /
RUN <<EOF
bash /opt/bin/update-m1n1-bootc.sh
dnf clean all && rm -rf /var/cache/dnf
bootc container lint
EOF

LABEL containers.bootc=1
LABEL ostree.bootable=1
LABEL org.opencontainers.image.title="asahi-bootc"
LABEL org.opencontainers.image.description="Fedora Asahi bootc base image for Apple Silicon (arm64) in the fjord homelab"
LABEL org.opencontainers.image.version="${VERSION_ID}"
LABEL org.opencontainers.image.source="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.url="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.documentation="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.vendor="MatchaScript"
LABEL org.opencontainers.image.base.name="quay.io/fedora/fedora-bootc:latest"

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
