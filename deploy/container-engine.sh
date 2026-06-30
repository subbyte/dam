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
