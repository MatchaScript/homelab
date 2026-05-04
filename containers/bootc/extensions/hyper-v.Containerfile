ARG BOOTC_BASE=quay.io/fedora/fedora-bootc:latest
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
