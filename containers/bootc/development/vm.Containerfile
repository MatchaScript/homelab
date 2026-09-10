ARG VM_BASE=ghcr.io/matchascript/fedora-development:latest
FROM ${VM_BASE}

RUN dnf install -y --setopt=install_weak_deps=False \
    cloud-init cloud-utils-growpart qemu-guest-agent \
    && dnf clean all

RUN systemctl enable qemu-guest-agent

RUN bootc container lint
LABEL ostree.bootable=1
LABEL containers.bootc=1
LABEL org.opencontainers.image.title="Dev Image (VM)"
LABEL org.opencontainers.image.description="Development Environment, KubeVirt VM variant (cloud-init, qemu-guest-agent)"
LABEL org.opencontainers.image.source="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.vendor="MatchaScript"
