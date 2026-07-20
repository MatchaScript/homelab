ARG DEV_BASE=ghcr.io/matchascript/fedora-bootc:latest

FROM ghcr.io/matchascript/fedora:latest AS tool-fetch
ARG TARGETARCH
RUN mkdir -p /tmp/bin \
    && curl -fsSL https://starship.rs/install.sh | sh -s -- --bin-dir /tmp/bin -y \
    && curl -fsSL https://mise.run | env MISE_INSTALL_PATH=/tmp/bin/mise sh \
    && curl -fsSL "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_${TARGETARCH}.tar.gz" \
        | tar xz -C /tmp && mv /tmp/krew-linux_${TARGETARCH} /tmp/bin/kubectl-krew \
    && CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt) \
    && curl -fsSL "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${TARGETARCH}.tar.gz" \
        | tar xz -C /tmp/bin \
    && HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/main/stable.txt) \
    && curl -fsSL "https://github.com/cilium/hubble/releases/download/${HUBBLE_VERSION}/hubble-linux-${TARGETARCH}.tar.gz" \
        | tar xz -C /tmp/bin \
    && curl -fsSL -o /tmp/bin/argocd "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${TARGETARCH}" \
    && chmod +x /tmp/bin/argocd

FROM ${DEV_BASE}

COPY overlay.d/01-timesyncd/ /
COPY overlay.d/01-container-mirror/ /
COPY overlay.d/10-zswap/ /
COPY overlay.d/10-vm-swapfile/ /

# ── Platform toolchain (refined from homelab-classic/envbox-base) ──
RUN dnf install -y --setopt=install_weak_deps=False --nodocs \
    zsh zsh-syntax-highlighting zsh-autosuggestions \
    systemd-networkd systemd-resolved bubblewrap tar nano vim \
    git-core gh sudo podman buildah skopeo chezmoi openbao opentofu helm \
    jq uv rustup ripgrep fd-find fzf btop openssh-clients openssh-server \
    fastfetch kubernetes-client k9s kind kustomize tar tuned btrfs-progs @development-tools \
    qemu-system-x86-core qemu-img \
    zswap-cli bcvk\
    && dnf clean all


COPY --from=tool-fetch /tmp/bin/ /usr/bin/

RUN systemctl enable tuned && \
    systemctl enable systemd-networkd && \
    systemctl enable sshd && \
    systemctl enable systemd-timesyncd && \
    systemctl enable var-swapfile.swap

RUN rm /var/{log,cache,lib}/* -rf
RUN bootc container lint
LABEL ostree.bootable=1
LABEL containers.bootc=1
LABEL org.opencontainers.image.title="Dev Image" \
    org.opencontainers.image.description="Development Environment" \
    org.opencontainers.image.source="https://github.com/MatchaScript/homelab" \
    org.opencontainers.image.vendor="MatchaScript"
