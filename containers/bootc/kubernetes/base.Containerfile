# Global build arguments
ARG SYSBASE=ghcr.io/matchascript/fedora-bootc:latest@sha256:10e934375e2ebb658ed66c28a776c92ed6130a18c0823e1c51f350eb7c822eac
ARG KUBEADM_VERSION="v1.35"

# Stage 1: Download kubeadm binary
FROM registry.fedoraproject.org/fedora-minimal:latest@sha256:959b2db1dac6850002b82cd80fd147f8cc829abe495a1c4ffbe9182a409c23e9 AS kubeadm-downloader
ARG KUBEADM_VERSION
ARG TARGETARCH # arm64 or amd64
RUN microdnf install -y curl && \
    RELEASE="$(curl -sSL https://dl.k8s.io/release/stable-${KUBEADM_VERSION#v}.txt)" && \
    mkdir -p /opt/bin && \
    curl -L -o /opt/bin/kubeadm "https://dl.k8s.io/release/${RELEASE}/bin/linux/${TARGETARCH}/kubeadm" && \
    chmod +x /opt/bin/kubeadm

# Stage 2: Main bootc image
FROM ${SYSBASE}

ARG KUBERNETES_VERSION="v1.35"
ARG KUBEADM_VERSION="v1.35"
ARG CRIO_VERSION=${KUBERNETES_VERSION}
ENV CRIO_VERSION=${CRIO_VERSION}
ENV KUBERNETES_VERSION=${KUBERNETES_VERSION}
ENV KUBEADM_VERSION=${KUBEADM_VERSION}
COPY overlay.d/10-kubernetes/ /

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
    sudo \
    vim \
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
