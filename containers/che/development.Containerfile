ARG DEV_BASE=docker.io/library/ubuntu:latest

FROM ${DEV_BASE} AS tool-fetch
ARG TARGETARCH
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
    && mkdir -p /tmp/bin \
    && tag() { curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's#.*/##'; } \
    && curl -fsSL https://starship.rs/install.sh | sh -s -- --bin-dir /tmp/bin -y \
    && curl -fsSL https://mise.run | env MISE_INSTALL_PATH=/tmp/bin/mise sh \
    && curl -fsSL https://get.chezmoi.io | sh -s -- -b /tmp/bin \
    && curl -fsSL https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/tmp/bin UV_NO_MODIFY_PATH=1 sh \
    && curl -fsSL "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_${TARGETARCH}.tar.gz" \
        | tar xz -C /tmp && mv /tmp/krew-linux_${TARGETARCH} /tmp/bin/kubectl-krew \
    && CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt) \
    && curl -fsSL "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${TARGETARCH}.tar.gz" \
        | tar xz -C /tmp/bin \
    && HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/main/stable.txt) \
    && curl -fsSL "https://github.com/cilium/hubble/releases/download/${HUBBLE_VERSION}/hubble-linux-${TARGETARCH}.tar.gz" \
        | tar xz -C /tmp/bin \
    && curl -fsSL -o /tmp/bin/argocd "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${TARGETARCH}" \
    && curl -fsSL -o /tmp/bin/kubectl "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl" \
    && curl -fsSL "https://get.helm.sh/helm-$(tag helm/helm)-linux-${TARGETARCH}.tar.gz" \
        | tar xz -C /tmp/bin --strip-components=1 "linux-${TARGETARCH}/helm" \
    && curl -fsSL "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${TARGETARCH}.tar.gz" \
        | tar xz -C /tmp/bin k9s \
    && V=$(tag opentofu/opentofu) \
    && curl -fsSL "https://github.com/opentofu/opentofu/releases/download/${V}/tofu_${V#v}_linux_${TARGETARCH}.tar.gz" \
        | tar xz -C /tmp/bin tofu \
    && V=$(tag openbao/openbao) \
    && curl -fsSL "https://github.com/openbao/openbao/releases/download/${V}/openbao_${V#v}_linux_${TARGETARCH}.tar.gz" \
        | tar xz -C /tmp/bin bao \
    && V=$(tag cli/cli) \
    && curl -fsSL "https://github.com/cli/cli/releases/download/${V}/gh_${V#v}_linux_${TARGETARCH}.tar.gz" \
        | tar xz -C /tmp/bin --strip-components=2 "gh_${V#v}_linux_${TARGETARCH}/bin/gh" \
    && chmod +x /tmp/bin/*

FROM ${DEV_BASE}

COPY overlay.d/01-container-mirror/ /

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    zsh zsh-syntax-highlighting zsh-autosuggestions locales ca-certificates curl \
    bubblewrap tar nano vim git sudo podman buildah skopeo uidmap passt \
    jq ripgrep fd-find fzf btop openssh-client openssh-server fastfetch kind kustomize \
    build-essential erofs-utils cephadm \
    && rm -rf /var/lib/apt/lists/* /etc/ssh/ssh_host_* \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && locale-gen en_US.UTF-8

# Docker CLI only: the daemon runs in the workspace's docker:dind sidecar and is
# reached through DOCKER_HOST.
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && . /etc/os-release \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       docker-ce-cli docker-buildx-plugin docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

COPY --from=tool-fetch /tmp/bin/ /usr/local/bin/
COPY overlay.d/20-che-sshd/ /

# Che runs workspace containers as 1234:0 on Kubernetes (DevWorkspace Operator
# default), with fsGroup 1234 as a supplementary group. /home/user is the
# persistent-home PVC mount, so nothing is put there.
RUN groupadd -g 1234 user \
    && useradd -u 1234 -g 0 -d /home/user -s /usr/bin/zsh user \
    && install -d -o 1234 -g 0 /home/user \
    && echo 'user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/user \
    && chmod 440 /etc/sudoers.d/user

ENV HOME=/home/user \
    SHELL=/usr/bin/zsh \
    LANG=C.UTF-8
USER 1234

# che-code is started by a postStart hook, so the container's own process must
# stay up; sshd in the foreground serves as that process.
CMD ["workspace-sshd"]

LABEL org.opencontainers.image.title="Dev Image (Che)" \
    org.opencontainers.image.description="Development Environment for Eclipse Che workspaces" \
    org.opencontainers.image.source="https://github.com/MatchaScript/homelab" \
    org.opencontainers.image.vendor="MatchaScript"
