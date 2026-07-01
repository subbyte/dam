#!/usr/bin/env bash
# Selects the local OCI build tool: prefer docker, fall back to podman, else error.
# Sourced by every mise task that builds/saves images. Sets $CONTAINER_ENGINE.
# A pre-set $CONTAINER_ENGINE is honored as a manual override.
if [ -z "${CONTAINER_ENGINE:-}" ]; then
  if command -v docker >/dev/null 2>&1; then
    CONTAINER_ENGINE=docker
  elif command -v podman >/dev/null 2>&1; then
    CONTAINER_ENGINE=podman
  else
    echo "ERROR: no container engine found — install docker or podman." >&2
    exit 1
  fi
fi
export CONTAINER_ENGINE

# Import a docker/oci-archive tar into k3s's containerd, then normalize podman's
# image names so pullPolicy:Never pods resolve. Podman tags a bare `-t platform-X`
# build as `localhost/platform-X`, whereas docker (and the kubelet, when resolving
# the chart's bare `platform-X:latest`) canonicalizes it to
# `docker.io/library/platform-X`. Podman's `localhost/` form survives save+import,
# so for every imported `localhost/platform-*` image add a `docker.io/library/...`
# tag under the `k8s.io` containerd namespace (the one the CRI/kubelet reads).
# No-op for docker, which never produces the `localhost/` form.
# Usage: k3s_import_images <tar> [lima_instance]   (omit instance ⇒ direct/IS_SANDBOX)
k3s_import_images() {
  local tar="$1" inst="${2:-}"
  local retag='sudo k3s ctr -n k8s.io images ls -q 2>/dev/null | grep "^localhost/platform-" | while read -r ref; do sudo k3s ctr -n k8s.io images tag --force "$ref" "docker.io/library/${ref#localhost/}" >/dev/null 2>&1 || true; done'
  if [ -z "$inst" ]; then
    sudo k3s ctr images import "$tar"
    bash -c "$retag"
  else
    limactl shell "$inst" sudo k3s ctr images import "$tar"
    limactl shell "$inst" bash -c "$retag"
  fi
}
