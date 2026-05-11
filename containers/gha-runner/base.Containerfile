ARG BASE_IMAGE="quay.io/fedora/fedora:latest@sha256:fe9ef21b59ac8e2e9510e352fa9d38f3bd171bf821a96f6b27918f78979db654"

# ── Stage 1: Download GHA runner binaries ────────────────────────────────────
FROM ${BASE_IMAGE} AS downloader

ARG TARGETARCH
ARG RUNNER_VERSION="2.332.0"
ARG RUNNER_CONTAINER_HOOKS_VERSION="0.8.1"

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y unzip \
    && mkdir -p /runner/k8s \
    && if [ "$TARGETARCH" = "arm64" ]; then RUNNER_ARCH="arm64"; else RUNNER_ARCH="x64"; fi \
    && curl -f -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz -C /runner \
    && rm runner.tar.gz \
    && curl -f -L -o runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
    && unzip ./runner-container-hooks.zip -d /runner/k8s \
    && rm runner-container-hooks.zip

# ── Stage 2: Runner setup ─────────────────────────────────────────────────────
FROM ${BASE_IMAGE} AS runner-build

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y \
    --exclude container-selinux \
    --exclude fuse-overlayfs \
    sudo \
    nodejs \
    skopeo \
    podman \
    buildah \
    jq \
    curl \
    git \
    unzip \
    uv \
    libicu

RUN rpm --setcaps shadow-utils 2>/dev/null
RUN groupadd docker --gid 123 \
    && useradd -m -d /home/runner -s /bin/bash -u 1001 -U -G docker runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner \
    && chmod 440 /etc/sudoers.d/runner

RUN echo "root:1:65535" > /etc/subuid \
    && echo "root:1:65535" > /etc/subgid \
    && echo "runner:1:1000" >> /etc/subuid \
    && echo "runner:1002:64534" >> /etc/subuid \
    && echo "runner:1:1000" >> /etc/subgid \
    && echo "runner:1002:64534" >> /etc/subgid

COPY --from=downloader --chown=runner:runner /runner/. /home/runner/

RUN sed -e 's|^#mount_program|mount_program|g' \
    -e '/additionalimage.*/a "/var/lib/shared",' \
    -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' \
    /usr/share/containers/storage.conf \
    > /etc/containers/storage.conf

RUN cat <<EOF > /etc/containers/containers.conf
[containers]
cgroups="disabled"
log_driver = "k8s-file"
[engine]
events_logger="file"
runtime="crun"
EOF

# ── Stage 3: Final image ──────────────────────────────────────────────────────
FROM scratch
COPY --from=runner-build / /

VOLUME /var/lib/containers
VOLUME /home/runner/.local/share/containers
RUN chown -R runner:runner /home/runner/

WORKDIR /home/runner
USER runner

ENV RUNNER_MANUALLY_TRAP_SIG=1 \
    ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1 \
    PATH="/home/runner/.local/bin:/home/runner:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    _CONTAINERS_USERNS_CONFIGURED="" \
    BUILDAH_ISOLATION=chroot \
    LANG=C.utf8

LABEL org.opencontainers.image.title="gha-runner-slim"
LABEL org.opencontainers.image.description="Slim Actions Runner Controller (ARC) image for a homelab cluster"
LABEL org.opencontainers.image.source="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.url="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.documentation="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.vendor="MatchaScript"
