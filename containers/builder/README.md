# builder

Image for the Buildbarn runner container that runs remote Bazel actions.

It is `fedora:minimal` plus the packages the tests need:

- `libyang-tools` — `yanglint`
- `librados-devel` — `librados.so`, which `-lrados` links against

The image has no entrypoint. Buildbarn injects `bb_runner` into the container, and `bb_runner` runs the actions.
