# n8n module

This is an experimental attempt at packaging [n8n](https://github.com/n8n-io/n8n) as a SelfPrivacy module.


# Unstable version

This was modified to work with unstable nixOs n8n version (1.91.0 at the time).
To do this :
 - Connect to selfPrivacy as root
 - Add this to /etc/nixos/deployment.nix
``` json
{ lib, pkgs, ... }: {
  # The content below is static and belongs to this deployment only!
  # Do not copy this configuration file to another NixOS installation!

  system.stateVersion = lib.mkDefault "24.05";
  environment.systemPackages = with pkgs; [ neovim nodejs ];
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "n8n" ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: prev: {
      n8n = (import (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
        sha256 = "0h8dhnw8j9ngxcj6wpyr8k1kx2jvwl4n5y2rk9ji7gv3iza4dspg";
      }) { system = final.system; config.allowUnfree = true; }).n8n.overrideAttrs (old: {
        # 4 Go pour NodeJS, évite l’OOM sur 8 Go RAM
        preBuild = (old.preBuild or "") + ''
          export NODE_OPTIONS="--max_old_space_size=4096"
        '';
      });
    })
  ];
}
```

 - then rebuild the flake
``` sh
cd /etc/nixos
nix flake update --override-input selfprivacy-nixos-config git+https://git.selfprivacy.org/SelfPrivacy/selfprivacy-nixos-config.git?ref=flakes
nixos-rebuild switch --flake .#default
```

 - Then enable it from selfPrivacy 
