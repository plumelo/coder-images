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
    file \
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
    nodejs \
    python3 \
    python3-venv \
    ripgrep \
    tmux

# Upgrade npm to latest version
npm install -g npm@latest

# Playwright system dependencies (Chromium + Firefox)
# (browser binaries are installed per-project via `npx playwright install`)
apt-get install -y --no-install-recommends \
    fonts-freefont-ttf \
    fonts-ipafont-gothic \
    fonts-liberation \
    fonts-noto-color-emoji \
    fonts-tlwg-loma-otf \
    fonts-unifont \
    fonts-wqy-zenhei \
    libasound2t64 \
    libatk-bridge2.0-0t64 \
    libatk1.0-0t64 \
    libatspi2.0-0t64 \
    libcairo2 \
    libcups2t64 \
    libdbus-1-3 \
    libdrm2 \
    libfontconfig1 \
    libfreetype6 \
    libgbm1 \
    libglib2.0-0t64 \
    libgtk-3-0t64 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libx11-6 \
    libxcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xfonts-cyrillic \
    xfonts-scalable \
    xvfb

# Install sops
curl -fsSLo /usr/local/bin/sops \
    https://github.com/getsops/sops/releases/download/v3.11.0/sops-v3.11.0.linux.amd64
chmod +x /usr/local/bin/sops

# Install ssh-to-age (for converting SSH keys to age keys)
curl -fsSLo /usr/local/bin/ssh-to-age \
    https://github.com/Mic92/ssh-to-age/releases/latest/download/ssh-to-age.linux-amd64
chmod +x /usr/local/bin/ssh-to-age

# Install tea (Gitea CLI)
curl -fsSLo /usr/local/bin/tea \
    https://gitea.com/gitea/tea/releases/download/v0.12.0/tea-0.12.0-linux-amd64
chmod +x /usr/local/bin/tea

# Install starship prompt
curl -fsSL https://starship.rs/install.sh | sh -s -- --yes

# Install uv (includes uvx)
curl -fsSL https://astral.sh/uv/install.sh | sh -s -- --no-modify-path
mv /root/.local/bin/uv /usr/local/bin/uv
mv /root/.local/bin/uvx /usr/local/bin/uvx

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

# Starship prompt configuration
# Place config in /etc/skel so it is copied into the home volume by the
# workspace init script (cp -rT /etc/skel ~) on every workspace start.
RUN mkdir -p /etc/skel/.config
COPY starship.toml /etc/skel/.config/starship.toml
RUN echo 'eval "$(starship init bash)"' >> /etc/skel/.bashrc

USER coder
