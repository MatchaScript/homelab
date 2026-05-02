ARG AMD64_BASE
FROM ${AMD64_BASE}

# Add kernel parameters
RUN mkdir -p /usr/lib/bootc/kargs.d && \
    cat <<EOF > /usr/lib/bootc/kargs.d/10-amd.toml
kargs = ["amd_iommu=on", "iommu=pt"]
EOF
