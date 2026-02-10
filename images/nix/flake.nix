{
  description = "Nix-built Docker image for Coder workspaces";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # Custom user/group setup for the coder user (uid/gid 1000)
      userSetup = with pkgs; [
        (writeTextDir "etc/passwd" ''
          root:x:0:0:root:/root:/bin/bash
          coder:x:1000:1000:coder:/home/coder:/bin/bash
        '')
        (writeTextDir "etc/group" ''
          root:x:0:
          coder:x:1000:
        '')
        (writeTextDir "etc/shadow" ''
          root:!x:::::::
          coder:!:::::::
        '')
        (writeTextDir "etc/gshadow" ''
          root:x::
          coder:x::
        '')
      ];

      # Nix configuration with flakes enabled
      nixConf = pkgs.writeTextDir "etc/nix/nix.conf" ''
        experimental-features = nix-command flakes
        trusted-users = root coder
      '';

      # Sudoers configuration for passwordless sudo
      sudoersConf = pkgs.writeTextDir "etc/sudoers.d/nopasswd" ''
        coder ALL=(ALL) NOPASSWD:ALL
      '';

      # Direnv configuration to source nix-direnv
      direnvrc = pkgs.writeTextDir "home/coder/.config/direnv/direnvrc" ''
        source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
      '';

      # nix-ld: library environment for running unpatched dynamic binaries.
      # This bundles common shared libraries so that pre-compiled binaries
      # (e.g. from npm, pip wheels, GitHub releases, VS Code Remote, rustup)
      # can find the libraries they need without patchelf or FHS wrappers.
      nix-ld-libraries = pkgs.buildEnv {
        name = "nix-ld-lib";
        pathsToLink = [ "/lib" ];
        paths = map pkgs.lib.getLib (with pkgs; [
          acl
          attr
          bzip2
          curl
          expat
          fontconfig
          freetype
          fuse3
          glib
          icu
          libGL
          libnotify
          libsodium
          libssh
          libunwind
          libusb1
          libuuid
          libxml2
          nss
          openssl
          stdenv.cc.cc
          systemd
          util-linux
          xz
          zlib
          zstd
        ]);
        extraPrefix = "/share/nix-ld";
        ignoreCollisions = true;
        postBuild = ''
          ln -s ${pkgs.stdenv.cc.bintools.dynamicLinker} $out/share/nix-ld/lib/ld.so
        '';
      };

      # Bashrc with direnv hook and bash completion
      bashrc = pkgs.writeTextDir "home/coder/.bashrc" ''
        # Source global profile if it exists
        if [ -f /etc/profile ]; then
          . /etc/profile
        fi

        # Bash completion
        if [ -f ${pkgs.bash-completion}/etc/profile.d/bash_completion.sh ]; then
          . ${pkgs.bash-completion}/etc/profile.d/bash_completion.sh
        fi

        # Direnv hook
        eval "$(direnv hook bash)"
      '';

    in
    {
      packages.${system} = {
        dockerImage = pkgs.dockerTools.buildLayeredImageWithNixDb {
          name = "ghcr.io/plumelo/coder-images";
          tag = "nix";
          maxLayers = 125;

          contents = with pkgs; [
            # Docker environment helpers
            dockerTools.usrBinEnv
            dockerTools.binSh
            dockerTools.caCertificates
            iana-etc

            # Core utilities
            bash
            bash-completion
            coreutils
            findutils
            gnugrep
            gnused
            gawk
            gnutar
            gzip
            less
            which
            procps

            # Networking
            curl
            iproute2
            openssh

            # Dev essentials
            git
            git-lfs
            jq
            gnumake
            gcc

            # Dev tools
            neovim
            nodejs
            gh
            ripgrep
            fd
            tmux

            # Secrets management
            sops
            age

            # Nix ecosystem
            nix
            direnv
            nix-direnv
            nix-ld

            # Locale support
            glibcLocales

            # User management
            sudo
            shadow

          ] ++ userSetup ++ [
            nixConf
            sudoersConf
            direnvrc
            bashrc
            nix-ld-libraries
          ];

          fakeRootCommands = ''
            # Create home directory and set ownership
            mkdir -p ./home/coder
            chown -R 1000:1000 ./home/coder

            # Create root home
            mkdir -p ./root

            # Create tmp with sticky bit
            mkdir -p ./tmp
            chmod 1777 ./tmp

            # Create /var/empty (needed by openssh)
            mkdir -p ./var/empty

            # Ensure sudoers file has correct permissions
            chmod 0440 ./etc/sudoers.d/nopasswd

            # nix-ld: create the dynamic linker shim at the standard FHS path
            # so unpatched binaries can find the interpreter
            mkdir -p ./lib64
            ln -sf ${pkgs.nix-ld}/libexec/nix-ld ./lib64/ld-linux-x86-64.so.2
          '';

          config = {
            Cmd = [ "/bin/bash" ];
            User = "coder";
            WorkingDir = "/home/coder";
            Env = [
              "PATH=/home/coder/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/bin:/usr/bin:/sbin:/usr/sbin"
              "LANG=en_US.UTF-8"
              "LANGUAGE=en_US.UTF-8"
              "LC_ALL=en_US.UTF-8"
              "LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive"
              "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
              "NIX_PAGER=cat"
              "NIX_LD=${nix-ld-libraries}/share/nix-ld/lib/ld.so"
              "NIX_LD_LIBRARY_PATH=${nix-ld-libraries}/share/nix-ld/lib"
              "USER=coder"
              "HOME=/home/coder"
            ];
          };
        };

        default = self.packages.${system}.dockerImage;
      };
    };
}
