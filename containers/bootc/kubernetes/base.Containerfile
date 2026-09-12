# Global build arguments
ARG SYSBASE
ARG KUBEADM_VERSION="v1.35"
# Built by .github/workflows/build-kata.yml from the netkit L3 fork
ARG KATA_REF="b2e0f6d193988bb6d29425af1ac81c532f63d06a"

# Stage 1: Download kubeadm binary
FROM registry.fedoraproject.org/fedora-minimal:latest@sha256:f2e7d9d06f6ecbf73334f1f9a9a7cc50862858f7eb692f610888146c2fa30d01 AS kubeadm-downloader
ARG KUBEADM_VERSION
ARG TARGETARCH # arm64 or amd64
RUN microdnf install -y curl && \
    RELEASE="$(curl -sSL https://dl.k8s.io/release/stable-${KUBEADM_VERSION#v}.txt)" && \
    mkdir -p /opt/bin && \
    curl -L -o /opt/bin/kubeadm "https://dl.k8s.io/release/${RELEASE}/bin/linux/${TARGETARCH}/kubeadm" && \
    chmod +x /opt/bin/kubeadm

# Stage 2: kata-containers install tree
ARG KATA_REF
FROM ghcr.io/matchascript/kata-artifacts:${KATA_REF} AS kata

# Stage 3: Main bootc image
FROM ${SYSBASE}

ARG KUBERNETES_VERSION="v1.35"
ARG KUBEADM_VERSION="v1.35"
ARG CRIO_VERSION=${KUBERNETES_VERSION}
ENV CRIO_VERSION=${CRIO_VERSION}
ENV KUBERNETES_VERSION=${KUBERNETES_VERSION}
ENV KUBEADM_VERSION=${KUBEADM_VERSION}
COPY overlay.d/01-timesyncd/ /
COPY overlay.d/01-container-mirror/ /
COPY overlay.d/10-kubernetes/ /
COPY overlay.d/10-zswap/ /
COPY overlay.d/10-vm-tuning/ /

RUN echo "$KUBERNETES_VERSION" > /etc/dnf/vars/kubever
RUN echo "$CRIO_VERSION" > /etc/dnf/vars/criover
RUN dnf install -y --setopt=install_weak_deps=False \
    --setopt=zchunk=False \
    --setopt=tsflags=nodocs \
    cri-o \
    kubelet \
    kubectl \
    crun \
    container-selinux \
    libseccomp \
    dbus-daemon \
    tuned \
    zswap-cli \
    sudo \
    nano \
    bubblewrap \
    openssh-server \
    python3-libselinux \
    python3-libsemanage \
    parted \
    btrfs-progs \
    lvm2 \
    systemd-networkd \
    fastfetch \
    systemd-resolved \
    greenboot \
    greenboot-default-health-checks && \
    dnf clean all

# Copy kubeadm from downloader stage
COPY --from=kubeadm-downloader /opt/bin/kubeadm /usr/bin/kubeadm

# cri-o reaches the shim, hypervisor and guest assets under /opt/kata by
# absolute path; only the CLI needs to be on PATH
COPY --from=kata /opt/kata /opt/kata
COPY overlay.d/20-kata/ /
RUN ln -s /opt/kata/bin/kata-runtime /usr/bin/kata-runtime && \
    command -v kata-runtime
RUN systemctl enable tuned && \
    systemctl enable systemd-networkd && \
    systemctl enable sshd && \
    systemctl enable systemd-timesyncd
RUN dnf clean all
RUN rm /var/{log,cache,lib}/* -rf
RUN bootc container lint
LABEL containers.bootc=1
LABEL ostree.bootable=1
LABEL org.opencontainers.image.title="kubernetes"
LABEL org.opencontainers.image.description="Kubernetes node bootc image (kubelet, kubeadm, cri-o) for a homelab cluster"
LABEL org.opencontainers.image.source="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.url="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.documentation="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.vendor="MatchaScript"
