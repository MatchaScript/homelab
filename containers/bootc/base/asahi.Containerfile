FROM quay.io/fedora/fedora-bootc:latest AS builder
# https://gitlab.com/fedora/bootc/base-images/-/issues/49
ARG TARGETARCH='arm64'
COPY overlay.d/50-asahi/ /
COPY overlay.d/99-asahi-builder/ /
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

LABEL containers.bootc 1
LABEL ostree.bootable 1
LABEL org.opencontainers.image.version="${VERSION_ID}"

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
