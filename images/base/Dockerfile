FROM ubuntu:noble

USER root
ENV DEBIAN_FRONTEND=noninteractive


RUN <<EOF
set -e

# Install base packages
apt-get update
apt-get install -y --no-install-recommends \
    age \
    bash \
    bash-completion \
    ca-certificates \
    curl \
    git \
    git-lfs \
    iproute2 \
    jq \
    locales \
    openssh-client \
    sudo

# Add NodeJS repository
curl -fsSL https://deb.nodesource.com/setup_24.x | bash -

# Add GitHub CLI repository
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list

# Install additional packages from external repos
apt-get update
apt-get install -y --no-install-recommends \
    build-essential \
    fd-find \
    gh \
    neovim \
    nodejs \
    ripgrep \
    tmux

# Install sops
curl -fsSLo /usr/local/bin/sops \
    https://github.com/getsops/sops/releases/download/v3.11.0/sops-v3.11.0.linux.amd64
chmod +x /usr/local/bin/sops

# Install starship prompt
curl -fsSL https://starship.rs/install.sh | sh -s -- --yes

# Cleanup
rm -rf /var/lib/apt/lists/*
EOF

# Generate the desired locale (en_US.UTF-8)
RUN locale-gen en_US.UTF-8

# Make typing unicode characters in the terminal work.
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Remove the `ubuntu` user and add a user `coder` so that you're not developing as the `root` user
RUN userdel -r ubuntu && \
    useradd coder \
    --create-home \
    --shell=/bin/bash \
    --uid=1000 \
    --user-group && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

USER coder

# Starship prompt configuration
COPY --chown=coder:coder starship.toml /home/coder/.config/starship.toml
RUN echo 'eval "$(starship init bash)"' >> /home/coder/.bashrc
