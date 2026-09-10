ARG AMD64_BASE
FROM ${AMD64_BASE}

# Add kernel parameters
RUN mkdir -p /usr/lib/bootc/kargs.d && \
    cat <<EOF > /usr/lib/bootc/kargs.d/10-amd.toml
kargs = ["amd_iommu=on", "iommu=pt"]
EOF

LABEL org.opencontainers.image.title="kubernetes-ryzen"
LABEL org.opencontainers.image.description="Kubernetes bootc image tuned for AMD Ryzen CPUs (AMD IOMMU)"
LABEL org.opencontainers.image.source="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.url="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.documentation="https://github.com/MatchaScript/homelab"
LABEL org.opencontainers.image.vendor="MatchaScript"
