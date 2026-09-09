#!/bin/bash

# ---------- logging helpers ----------
log()  { echo -e "\n========== $* ==========\n"; }
info() { echo "✔ $*"; }
warn() { echo "⚠ $*"; }
err()  { echo "✖ $*" >&2; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }



# ---------- sudo detection ----------
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo "✖ This script needs root privileges or sudo installed." >&2
        exit 1
    fi
fi


# ---------- os detection ----------
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="${ID}"
        OS_LIKE="${ID_LIKE:-}"
    else
        err "Unable to detect OS."
    fi

    case "$OS_ID" in
        ubuntu|debian)
            PACKAGE_MANAGER="apt"
            PKG_INSTALL="$SUDO apt-get install -y"
            PKG_UPDATE="$SUDO apt-get update -y"
            ;;
        fedora|rhel|centos)
            PACKAGE_MANAGER="dnf"
            PKG_INSTALL="$SUDO dnf install -y"
            PKG_UPDATE="$SUDO dnf -y update"
            ;;
        amzn)
            # Amazon Linux 2 -> yum, Amazon Linux 2023 -> dnf
            if command_exists dnf; then
                PACKAGE_MANAGER="dnf"
                PKG_INSTALL="$SUDO dnf install -y"
                PKG_UPDATE="$SUDO dnf -y update"
            else
                PACKAGE_MANAGER="yum"
                PKG_INSTALL="$SUDO yum install -y"
                PKG_UPDATE="$SUDO yum update -y"
            fi
            ;;
        arch|manjaro)
            PACKAGE_MANAGER="pacman"
            PKG_INSTALL="$SUDO pacman -S --noconfirm"
            PKG_UPDATE="$SUDO pacman -Sy"
            ;;
        *)
            err "Unsupported OS: $OS_ID"
            ;;
    esac

    info "Detected OS: $OS_ID ($PACKAGE_MANAGER)"
}

# ---------- arch detection ----------
detect_arch() {
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64) ARCH_NAME="amd64" ;;
        aarch64|arm64) ARCH_NAME="arm64" ;;
        armv7*|armhf) ARCH_NAME="arm" ;;
        *) ARCH_NAME="amd64" ;;
    esac

    info "Detected architecture: $ARCH_NAME"
}

# ---------- common packages ----------
ensure_common_packages() {
    log "Installing common packages..."

    $PKG_UPDATE

    case "$PACKAGE_MANAGER" in
        apt)
            $PKG_INSTALL jq git curl wget btop unzip sed coreutils gnupg ca-certificates \
                openssh-client lsb-release vim nano tar gzip cron logrotate
            ;;
        dnf)
            $PKG_INSTALL jq git curl wget btop unzip sed coreutils gnupg2 ca-certificates \
                openssh vim nano tar gzip cronie logrotate
            ;;
        yum)
            $PKG_INSTALL jq git curl wget btop unzip sed coreutils gnupg2 ca-certificates \
                openssh vim nano tar gzip cronie logrotate
            ;;
        pacman)
            $PKG_INSTALL jq git curl wget btop unzip sed coreutils gnupg ca-certificates \
                openssh vim nano tar gzip cronie logrotate
            ;;
        *)
            err "Unsupported package manager: $PACKAGE_MANAGER"
            ;;
    esac

    info "Common packages installed."
}
# ---------- docker ----------
install_docker() {
    if command_exists docker; then
        log "Docker already installed."
        return
    fi

    log "Installing Docker..."

    case "$PACKAGE_MANAGER" in
        apt)
            $SUDO apt-get update -y
            $SUDO apt-get install -y ca-certificates curl gnupg

            $SUDO install -m 0755 -d /etc/apt/keyrings

            curl -fsSL https://download.docker.com/linux/$OS_ID/gpg \
                | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg

            echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/$OS_ID $(lsb_release -cs) stable" \
                | $SUDO tee /etc/apt/sources.list.d/docker.list

            $SUDO apt-get update -y
            $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io
            ;;
        dnf)
            $SUDO dnf -y install dnf-plugins-core
            $SUDO dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            $SUDO dnf install -y docker-ce docker-ce-cli containerd.io
            ;;
        yum)
            # Amazon Linux 2 - use amazon-linux-extras if available, else Docker's CE repo
            if command_exists amazon-linux-extras; then
                $SUDO amazon-linux-extras install docker -y
            else
                $SUDO yum install -y yum-utils
                $SUDO yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                $SUDO yum install -y docker-ce docker-ce-cli containerd.io
            fi
            ;;
        pacman)
            $SUDO pacman -S --noconfirm docker
            ;;
        *)
            err "Unsupported package manager for Docker install: $PACKAGE_MANAGER"
            ;;
    esac

    $SUDO systemctl enable --now docker
    $SUDO usermod -aG docker "$USER"
    info "Docker installed. NOTE: log out and back in (or run 'newgrp docker') for group changes to take effect."
}

# ---------- aws cli ----------
install_aws_cli() {
    if command_exists aws; then
        log "AWS CLI already installed."
        return
    fi

    log "Installing AWS CLI for arch: $ARCH_NAME"

    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' RETURN
    cd "$tmp"

    case "$ARCH_NAME" in
        amd64)
            CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
            ;;
        arm64)
            CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
            ;;
        *)
            err "Unsupported architecture for AWS CLI: $ARCH_NAME"
            ;;
    esac

    curl -fsSL "$CLI_URL" -o awscliv2.zip
    unzip -q awscliv2.zip
    $SUDO ./aws/install

    cd - >/dev/null
    info "AWS CLI installation complete."
}

# ---------- verification ----------
verify_installation() {
    log "Verifying installed packages..."

    local fail=0

    # git
    if command_exists git; then
        info "git: $(git --version)"
    else
        warn "git: NOT installed"
        fail=1
    fi

    # curl
    if command_exists curl; then
        info "curl: $(curl --version | head -n1)"
    else
        warn "curl: NOT installed"
        fail=1
    fi

    # jq
    if command_exists jq; then
        info "jq: $(jq --version)"
    else
        warn "jq: NOT installed"
        fail=1
    fi

    # docker
    if command_exists docker; then
        info "docker: $(docker --version)"
        if $SUDO systemctl is-active --quiet docker; then
            info "docker service: running"
        else
            warn "docker service: NOT running"
            fail=1
        fi
    else
        warn "docker: NOT installed"
        fail=1
    fi

    # aws cli
    if command_exists aws; then
        info "aws-cli: $(aws --version)"
    else
        warn "aws-cli: NOT installed"
        fail=1
    fi

    echo ""
    if [ "$fail" -eq 0 ]; then
        info "All packages verified successfully."
    else
        warn "One or more packages failed verification. Check logs above."
    fi
}