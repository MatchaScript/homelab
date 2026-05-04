ARG AMD64_BASE
FROM ${AMD64_BASE}

# Install intel-lpmd
RUN dnf install -y --setopt=install_weak_deps=False intel-lpmd && dnf clean all

# Add kernel parameters
RUN mkdir -p /usr/lib/bootc/kargs.d && \
    cat <<EOF > /usr/lib/bootc/kargs.d/10-intel.toml
kargs = ["intel_iommu=on", "iommu=pt"]
EOF

LABEL org.opencontainers.image.title="kubernetes-intel"
LABEL org.opencontainers.image.description="Kubernetes bootc image tuned for Intel CPUs (intel-lpmd, IOMMU)"
LABEL org.opencontainers.image.source="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.url="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.documentation="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.vendor="MatchaScript"
