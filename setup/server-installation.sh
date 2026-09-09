#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR"


source "$SCRIPT_DIR/dependencies.sh"

main() {
    log "Starting server bootstrap"

    detect_os
    detect_arch
    ensure_common_packages
    install_docker
    install_aws_cli

    log "Server bootstrap complete"
}

main "$@"