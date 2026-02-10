# coder-images

Base images for Coder workspaces.

## Images

| Image | Tag | Contents |
|-------|-----|----------|
| Base | `:base` | Ubuntu Noble + bash, bash-completion, git, curl, Node.js 24, gh CLI, neovim, ripgrep, fd-find, tmux, build-essential, age, sops |
| Nix | `:nix` | Nix-built image + bash, bash-completion, git, curl, Node.js, gh CLI, neovim, ripgrep, fd, tmux, gcc, make, sops, age, nix, direnv, nix-direnv, nix-ld |
| DevOps | `:devops` | Base + Terraform, Packer, tflint |

## Usage

```dockerfile
# Base image
FROM ghcr.io/plumelo/coder-images:base

# Nix image (includes nix, direnv, nix-ld)
FROM ghcr.io/plumelo/coder-images:nix

# DevOps image (includes Terraform, Packer, tflint)
FROM ghcr.io/plumelo/coder-images:devops
```

## Adding New Variants

1. Create a new directory under `images/` with a `Dockerfile`:
   ```dockerfile
   ARG BASE_IMAGE=ghcr.io/plumelo/coder-images:base
   FROM ${BASE_IMAGE}

   USER root
   # Install your tools here
   USER coder
   ```

2. Add the variant name to the matrix in `.github/workflows/build.yml`:
   ```yaml
   strategy:
     matrix:
       variant:
         - devops
         - your-new-variant
   ```

## Local Testing

```bash
# Build base image
docker build -t test-base ./images/base

# Build variant using local base
docker build --build-arg BASE_IMAGE=test-base -t test-devops ./images/devops

# Build nix image (requires nix with flakes enabled)
nix build ./images/nix#dockerImage
docker load < result

# Verify tools
docker run --rm test-base sops --version
docker run --rm test-base age --version
docker run --rm test-devops terraform version
docker run --rm test-devops packer version
docker run --rm test-devops tflint --version
```
