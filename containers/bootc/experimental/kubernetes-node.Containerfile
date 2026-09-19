# Global build arguments
ARG SYSBASE
FROM ${SYSBASE}

ARG KUBERNETES_VERSION="v1.35"
ARG CRIO_VERSION=${KUBERNETES_VERSION}
ENV CRIO_VERSION=${CRIO_VERSION}
ENV KUBERNETES_VERSION=${KUBERNETES_VERSION}

# Only the parts of the Kubernetes overlay that a node without kubeadm and
# without kata needs: the package repositories and the kernel settings.
COPY overlay.d/10-kubernetes/etc/yum.repos.d/cri-o.repo /etc/yum.repos.d/cri-o.repo
COPY overlay.d/10-kubernetes/etc/yum.repos.d/kubernetes.repo /etc/yum.repos.d/kubernetes.repo
COPY overlay.d/10-kubernetes/usr/lib/modules-load.d/br_netfilter.conf /usr/lib/modules-load.d/br_netfilter.conf
COPY overlay.d/10-kubernetes/usr/lib/sysctl.d/60-kube.conf /usr/lib/sysctl.d/60-kube.conf

RUN echo "$KUBERNETES_VERSION" > /etc/dnf/vars/kubever
RUN echo "$CRIO_VERSION" > /etc/dnf/vars/criover
# Both container runtimes ship in the image; a VM's cloud-init picks one.
RUN dnf install -y --setopt=install_weak_deps=False \
    --setopt=zchunk=False \
    --setopt=tsflags=nodocs \
    cri-o \
    containerd \
    kubelet \
    kubectl \
    cri-tools \
    crun \
    container-selinux \
    containernetworking-plugins \
    openssh-server \
    sudo \
    systemd-networkd \
    systemd-resolved \
    policycoreutils-python-utils \
    setools-console \
    audit \
    cloud-init \
    cloud-utils-growpart \
    qemu-guest-agent && \
    dnf clean all

# After the install: the containerd package owns /etc/containerd/config.toml.
COPY overlay.d/30-experimental-node/ /

# The Fedora preset enables cloud-config, cloud-final, cloud-init-main and
# cloud-init-local, but not cloud-init-network.service.
RUN systemctl enable sshd && \
    systemctl enable systemd-networkd && \
    systemctl enable qemu-guest-agent && \
    systemctl enable cloud-init-network && \
    systemctl enable bootc-usr-overlay

RUN dnf clean all
RUN rm /var/{log,cache,lib}/* -rf
RUN bootc container lint
LABEL containers.bootc=1
LABEL ostree.bootable=1
LABEL org.opencontainers.image.title="kubernetes-experimental"
LABEL org.opencontainers.image.description="Experimental Kubernetes node bootc image (kubelet, cri-o and containerd, SELinux investigation tools)"
LABEL org.opencontainers.image.source="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.url="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.documentation="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.vendor="MatchaScript"
