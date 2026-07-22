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

FROM scratch AS base
COPY --from=builder /target-rootfs/ /
COPY overlay.d/01-common/ /
COPY overlay.d/01-growpart/ /
COPY overlay.d/50-asahi/ /
RUN dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs cloud-utils-growpart
RUN <<EOF
bash /opt/bin/update-m1n1-bootc.sh
dnf clean all && rm -rf /var/cache/dnf
EOF

# ── tps6598x (tipd) module rebuild with the GAID boot-renegotiation patch ──
# USB3 devices plugged in before boot never link-train on Apple Silicon;
# see the patch header for the mechanism and verification record. This
# stage carries all build tooling and kernel source and is discarded
# entirely — the final stage copies in only the staged module file.
# A patch application failure or vermagic mismatch fails the build on
# purpose: that is the rot check for kernel bumps.
FROM base AS modbuilder
COPY overlay.d/98-asahi-modbuilder/ /
RUN <<'EOF'
set -euo pipefail

KVER=$(rpm -ql kernel-16k-core | sed -n 's#^\(/usr\)\?/lib/modules/\([^/]*\)/vmlinuz$#\2#p' | head -n1)
[ -n "$KVER" ] || { echo "ERROR: cannot determine kernel version from kernel-16k-core" >&2; exit 1; }
KPKG=$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-16k-core)
KVER_UPSTREAM=$(rpm -q --qf '%{VERSION}\n' kernel-16k-core)
echo "modbuilder: building patched tps6598x for KVER=${KVER} (pkg ${KPKG})"

BUILD_ROOT=/tmp/modbuild
mkdir -p "$BUILD_ROOT"
dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
    dnf5-plugins rpm-build patch git binutils xz zstd gzip "kernel-16k-devel-${KPKG}"

SRC_DIR=""
if dnf download --source --destdir "$BUILD_ROOT" "kernel-16k-${KPKG}"; then
    SRPM=$(find "$BUILD_ROOT" -maxdepth 1 -name '*.src.rpm' | head -n1)
    if [ -n "$SRPM" ] && rpmbuild --define "_topdir ${BUILD_ROOT}/rpmbuild" -rp --nodeps "$SRPM"; then
        CORE_PATH=$(find "${BUILD_ROOT}/rpmbuild/BUILD" -path '*/drivers/usb/typec/tipd/core.c' -print -quit)
        [ -n "$CORE_PATH" ] && SRC_DIR="${CORE_PATH%/drivers/usb/typec/tipd/core.c}"
    fi
fi
if [ -z "$SRC_DIR" ] || [ ! -d "$SRC_DIR" ]; then
    echo "modbuilder: src.rpm path unavailable, falling back to AsahiLinux/linux git clone" >&2
    TAG=$(git ls-remote --tags --refs https://github.com/AsahiLinux/linux \
            "refs/tags/asahi-${KVER_UPSTREAM}-*" \
          | sed 's#.*refs/tags/##' | sort -V | tail -n1)
    [ -n "$TAG" ] || { echo "ERROR: no AsahiLinux/linux tag matches upstream version ${KVER_UPSTREAM}" >&2; exit 1; }
    SRC_DIR="${BUILD_ROOT}/linux-src"
    git clone --depth 1 --branch "$TAG" https://github.com/AsahiLinux/linux "$SRC_DIR"
fi

patch -p1 --fuzz=0 -d "$SRC_DIR" < /usr/share/asahi-patches/tipd-gaid-boot-renegotiation.patch

BUILD_DIR="/usr/lib/modules/${KVER}/build"
[ -d "$BUILD_DIR" ] || BUILD_DIR="/usr/src/kernels/${KVER}"
[ -d "$BUILD_DIR" ] || { echo "ERROR: no kernel build dir for ${KVER}" >&2; exit 1; }

make -C "$BUILD_DIR" M="${SRC_DIR}/drivers/usb/typec/tipd" modules

MODULE="${SRC_DIR}/drivers/usb/typec/tipd/tps6598x.ko"
[ -f "$MODULE" ] || { echo "ERROR: build did not produce tps6598x.ko" >&2; exit 1; }
VERMAGIC=$(modinfo -F vermagic "$MODULE" | awk '{print $1}')
[ "$VERMAGIC" = "$KVER" ] || { echo "ERROR: vermagic mismatch: module=${VERMAGIC} kernel=${KVER}" >&2; exit 1; }

# Stage the module under /out with the same name and compression as the
# stock module, so the final stage can overlay it with a plain COPY.
MODDIR="/usr/lib/modules/${KVER}/kernel/drivers/usb/typec/tipd"
STOCK=$(find "$MODDIR" -maxdepth 1 -type f -name 'tps6598x.ko*' -print -quit)
[ -n "$STOCK" ] || { echo "ERROR: stock tps6598x module not found in ${MODDIR}" >&2; exit 1; }
case "$STOCK" in
    *.ko.xz)  xz --check=crc32 -f "$MODULE"; SUFFIX=.xz ;;
    *.ko.zst) zstd -f "$MODULE"; SUFFIX=.zst ;;
    *.ko.gz)  gzip -f "$MODULE"; SUFFIX=.gz ;;
    *.ko)     SUFFIX= ;;
    *)        echo "ERROR: unrecognized stock module name ${STOCK}" >&2; exit 1 ;;
esac
install -D -m 0644 "${MODULE}${SUFFIX}" "/out${MODDIR}/$(basename "$STOCK")"
echo "modbuilder: staged /out${MODDIR}/$(basename "$STOCK")"
EOF

FROM base
ARG VERSION_ID
COPY --from=modbuilder /out/ /
RUN <<'EOF'
set -euo pipefail
KVER=$(rpm -ql kernel-16k-core | sed -n 's#^\(/usr\)\?/lib/modules/\([^/]*\)/vmlinuz$#\2#p' | head -n1)
[ -n "$KVER" ] || { echo "ERROR: cannot determine kernel version from kernel-16k-core" >&2; exit 1; }
depmod -a "$KVER"

# Regenerate the initramfs: it carries its own copy of tps6598x, which
# loads in early boot and would otherwise shadow the patched module on
# the root fs for the entire lifetime of the system. Plain dracut is
# used on purpose: kernel-install would run the asahi m1n1 hook, which
# needs an ESP and cannot work at image-build time.
INITRD="/usr/lib/modules/${KVER}/initramfs.img"
# /root is a symlink to /var/roothome, which does not exist at image
# build time; dracut fails on the dangling symlink without this.
mkdir -p /var/roothome
dracut --force --no-hostonly "$INITRD" "$KVER"
rmdir /var/roothome
[ -f "$INITRD" ] || { echo "ERROR: dracut did not produce ${INITRD}" >&2; exit 1; }

# The initramfs copy must be byte-identical to the patched module on
# the root fs, or early boot will load the stock driver and shadow it.
MODPATH="usr/lib/modules/${KVER}/kernel/drivers/usb/typec/tipd/tps6598x.ko.xz"
if ! lsinitrd -f "$MODPATH" "$INITRD" | cmp -s - "/${MODPATH}"; then
    echo "ERROR: regenerated initramfs does not carry the patched tps6598x" >&2
    exit 1
fi

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
