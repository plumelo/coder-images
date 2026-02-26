ARG BASE_IMAGE=ghcr.io/plumelo/coder-images:base
FROM ${BASE_IMAGE}

USER root

RUN <<EOF
set -e

apt-get update
apt-get install -y --no-install-recommends gnupg software-properties-common unzip xz-utils

# Add HashiCorp repository
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list

# Add Azure CLI repository
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/azure-cli.list

# Install tflint
curl -fsSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install Terraform, Packer, and Azure CLI from external repos
apt-get update
apt-get install -y --no-install-recommends \
    terraform \
    packer \
    azure-cli

# Cleanup
rm -rf /var/lib/apt/lists/*

# Create /nix owned by coder for single-user Nix install
mkdir -p /nix
chown coder:coder /nix
EOF

USER coder

# Install Nix in single-user mode (no daemon, no systemd required)
RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon

# Enable flakes and nix-command
RUN mkdir -p ~/.config/nix && \
    echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf

ENV PATH="/home/coder/.nix-profile/bin:${PATH}"
