# gha-runner

Self-hosted runner images for Actions Runner Controller (ARC).

## Variants

- `gha-runner-slim` — runner binary + podman/buildah + core tools
- `gha-runner` — `slim` plus build tools (gcc, cmake, python3-devel) and linters

## Notes

- **Userns isolation** instead of Kata: Kata does not support Netkit L3 yet. Switch to Kata once supported.
- **SHA1 enabled** in `default.Containerfile`: required for SSH to Catalyst 3560CX. Remove when the device is replaced.
