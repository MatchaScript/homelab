ARG DEV_BASE=ghcr.io/matchascript/fedora-bootc:latest
FROM ${DEV_BASE}

COPY overlay.d/01-timesyncd/ /
COPY overlay.d/01-container-mirror/ /

# ── Platform toolchain (refined from homelab-classic/envbox-base) ──
RUN dnf install -y --setopt=install_weak_deps=False --nodocs \
    zsh zsh-syntax-highlighting zsh-autosuggestions \
    systemd-networkd systemd-resolved bubblewrap nano vim \
    git-core gh sudo podman buildah skopeo chezmoi helm \
    jq uv rustup ripgrep fd-find fzf btop openssh-clients openssh-server \
    fastfetch kubernetes-client k9s kind kustomize tar tuned @development-tools \
    && dnf clean all


RUN curl -fsSL https://starship.rs/install.sh | sh -s -- --bin-dir /usr/bin -y \
    && curl -fsSL https://mise.run | env MISE_INSTALL_PATH=/usr/bin/mise sh

RUN systemctl enable tuned && \
    systemctl enable systemd-networkd && \
    systemctl enable sshd && \
    systemctl enable systemd-timesyncd

RUN rm /var/{log,cache,lib}/* -rf
RUN bootc container lint
LABEL ostree.bootable=1
LABEL containers.bootc=1
LABEL org.opencontainers.image.title="Dev Image" \
    org.opencontainers.image.description="Development Environment" \
    org.opencontainers.image.source="https://github.com/MatchaScript/homelab" \
    org.opencontainers.image.vendor="MatchaScript"
