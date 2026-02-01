ARG BASE_IMAGE=ghcr.io/plumelo/coder-images:base
FROM ${BASE_IMAGE}

USER root

RUN <<EOF
set -e

# Install HashiCorp repository
apt-get update
apt-get install -y --no-install-recommends gnupg software-properties-common unzip

curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list

# Install tflint
curl -fsSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install Terraform and Packer from HashiCorp repo
apt-get update
apt-get install -y --no-install-recommends \
    terraform \
    packer

# Cleanup
rm -rf /var/lib/apt/lists/*
EOF

USER coder
