ARG BASE_IMAGE="ghcr.io/matchascript/gha-runner-slim:latest@sha256:d58e3eef49e25e8871ebb6a6122f4b4aa40d8eb39ac4ad8c563c12adef4c0d14"

# ── Stage 1: Install packages ────────────────────────────────────────────────
FROM ${BASE_IMAGE} AS default-build

USER root

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y \
    gcc \
    gcc-c++ \
    make \
    cmake \
    autoconf \
    automake \
    python3-devel \
    openssl-devel \
    libssh-devel \
    wget \
    rsync \
    openssh-clients \
    shellcheck \
    yamllint
RUN update-crypto-policies --set DEFAULT:SHA1
# ── Stage 2: Final image ─────────────────────────────────────────────────────
FROM scratch
COPY --from=default-build / /

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

LABEL org.opencontainers.image.title="gha-runner"
LABEL org.opencontainers.image.description="Default Actions Runner Controller (ARC) image with build toolchains for a homelab cluster"
LABEL org.opencontainers.image.source="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.url="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.documentation="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.vendor="MatchaScript"
