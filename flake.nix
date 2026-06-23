{
  description = "My Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
  let
    configuration = { pkgs, ... }: {

      # 1. Essential fixes for Determinate Systems & Modern nix-darwin
      nix.enable = false;                     # Let Determinate manage Nix
      system.stateVersion = 5;
      system.primaryUser = "etka";            # Required for Homebrew/activation

      # nixpkgs.hostPlatform is now required
      nixpkgs.hostPlatform = "aarch64-darwin"; # Use "x86_64-darwin" if on Intel
      nixpkgs.config.allowUnfree = true;

      # 2. CLI Tools (Nix Native)
      environment.systemPackages = [
        pkgs.bat
        pkgs.btop
        pkgs.ffmpeg
        pkgs.nodejs
        pkgs.pnpm
        pkgs.zoxide
        pkgs.uv
        pkgs.delta
        pkgs.rustc
        pkgs.cargo
        pkgs.rustfmt
        pkgs.clippy
	pkgs.ttyper
	pkgs.gradle_9
	pkgs.terraform
      ];

      # 2.5. Shell aliases
      environment.shellAliases = {
        ll = "ls -alh";
        la = "ls -a";
        ".." = "z ..";
        "..." = "z ../..";
        update = "brew update && sudo darwin-rebuild switch --flake ~/.config/nix-darwin";
      };

      # 2.6. Zsh + Oh My Zsh
      programs.zsh.enable = true;
      programs.zsh.interactiveShellInit = ''
        eval "$(zoxide init zsh --cmd cd)"
      '';

      environment.variables.EDITOR = "zed --wait";
      environment.variables.JAVA_HOME = "/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home";

      users.users.etka = {
        name = "etka";
        home = "/Users/etka";
      };

      # Touch ID for sudo
      security.pam.services.sudo_local.touchIdAuth = true;

      # Dock
      system.defaults.dock = {
        autohide = false;
        show-recents = false;
        mru-spaces = false;
        persistent-apps = [
          "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
          "/System/Applications/Messages.app"
          "/System/Applications/Calendar.app"
          "/System/Applications/App Store.app"
          "/System/Applications/System Settings.app"
          "/Applications/Zed.app"
          "/Applications/Claude.app"
          "/Applications/cmux.app"
          "/Applications/Vivaldi.app"
        ];
      };

      home-manager.users.etka = { pkgs, ... }: {
        programs.zsh = {
          enable = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          shellAliases = {
            ll = "ls -alh";
            la = "ls -a";
            ".." = "z ..";
            "..." = "z ../..";
            update = "brew update && sudo darwin-rebuild switch --flake ~/.config/nix-darwin";
          };
          oh-my-zsh = {
            enable = true;
            theme = "agnoster";
            plugins = [
              "git"
              "docker"
              "sudo"
              "z"
              "history"
              "colored-man-pages"
              "command-not-found"
              "extract"
              "aliases"
            ];
          };
          initExtra = ''
            export PATH="$HOME/.local/bin:$PATH"
            eval "$(zoxide init zsh --cmd cd)"
            eval "$(direnv hook zsh)"
            claude-local() {
              ANTHROPIC_BASE_URL=http://localhost:8001 \
              ANTHROPIC_API_KEY=dummy \
              ANTHROPIC_AUTH_TOKEN=dummy \
              ANTHROPIC_DEFAULT_OPUS_MODEL=my-model \
              ANTHROPIC_DEFAULT_SONNET_MODEL=my-model \
              ANTHROPIC_DEFAULT_HAIKU_MODEL=my-model \
              claude "$@"
            }
          '';
        };
        programs.delta = {
          enable = true;
          enableGitIntegration = true;
        };
        programs.git = {
          enable = true;
          settings = {
            user.name = "ahmetmutlugun";
            user.email = "ahmet.mutlugun@gmail.com";
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
            pull.rebase = true;
          };
          signing.format = null;
        };
        home.stateVersion = "24.11";
      };

      # 3. GUI Apps & Fast-moving CLI (via Homebrew)
      homebrew = {
        enable = true;
        onActivation.cleanup = "zap";
        onActivation.upgrade = true;
        taps = [
          "supabase/tap"
        ];
        brews = [
	  "gh"
	  "go"
	  "sevenzip"
	  "direnv"
	  "gemini-cli"
	  "pi-coding-agent"
          "ripgrep"
	  "llama.cpp"
	  "yt-dlp"
          "fd"
	  "cloudflared"
 	  "cmake"
	  "mlx-lm"
	  "kotlin-language-server"
          "vapor"
	  "arm-none-eabi-gcc"
	  "opencode"
	  "ollama"
	  "mlx"
	  "7zip"
	  "supabase/tap/supabase"
        ];
        casks = [
          "zed"
          "firefox"
          "claude"
          "cmux"
          "karabiner-elements"
          "scroll-reverser"
          "docker-desktop"
          "betterdisplay"
	  "steam"
	  "gcc-arm-embedded"
          "discord"
	  "visual-studio-code"
          "beekeeper-studio"
          "obsidian"
          "raycast"
          "vlc"
          "caffeine"
          "google-chrome"
          "bitwarden"
          "crossover"
          "appcleaner"
	  "unnaturalscrollwheels"
	  "temurin@21"
          "omnidisksweeper"
	  "android-commandlinetools"
          "vivaldi"
          "stats"
	  "ghostty"
          "gcloud-cli"
	  "prismlauncher"
	  "segger-jlink"
	  "rawtherapee"
	  "android-studio"
        ];
      };
    };
  in
  {
    darwinConfigurations."etkamac" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        home-manager.darwinModules.home-manager
      ];
    };
  };
}
