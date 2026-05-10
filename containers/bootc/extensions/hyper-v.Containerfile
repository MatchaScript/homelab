ARG BOOTC_BASE=quay.io/fedora/fedora-bootc:latest@sha256:226100ec19a5d94defd4737a26a29bee3c24a9f9ddeca56092049c847d911f3b
FROM ${BOOTC_BASE}
ARG VERSION_ID
RUN dnf install -y hyperv-daemons && \
    dnf clean all
RUN systemctl enable hypervfcopyd && \
    systemctl enable hypervkvpd && \
    systemctl enable hypervvssd

RUN rm /var/{log,cache,lib}/* -rf
RUN bootc container lint

LABEL org.opencontainers.image.title="fedora-bootc-hyperv"
LABEL org.opencontainers.image.description="Fedora bootc image with Hyper-V guest integration services"
LABEL org.opencontainers.image.version="${VERSION_ID}"
LABEL org.opencontainers.image.source="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.url="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.documentation="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.vendor="MatchaScript"
