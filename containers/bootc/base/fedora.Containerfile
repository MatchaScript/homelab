ARG BOOTC_BASE
FROM ${BOOTC_BASE} AS builder
ARG TARGETARCH='amd64'

# Skip compose-time systemd-sysusers in bwrap, avoiding Permission denied on mode-0000 /etc/gshadow
RUN sed -i '1i sysusers: none' /usr/share/doc/bootc-base-imagectl/manifests/fedora-minimal.yaml \
    /usr/share/doc/bootc-base-imagectl/manifests/minimal/manifest.yaml 2>/dev/null || true
RUN /usr/libexec/bootc-base-imagectl build-rootfs --manifest=fedora-minimal /target-rootfs
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
RUN dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs cloud-utils-growpart
# Regenerate the file contexts so genhomedircon picks up HOME=/var/home from
# overlay.d/01-common/etc/default/useradd.  Without this the home rules stay
# under /home while subs_dist sends lookups to /var/home, and everything below
# /var/home falls through to var_t.
RUN semodule -B && \
    F=/etc/selinux/targeted/contexts/files/file_contexts.homedirs && \
    grep -qE '^/var/home/' "$F"
RUN dnf clean all && rm -rf /var/cache/dnf && bootc container lint
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
