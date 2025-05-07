{
  description = "n8n module";

  outputs = { self }: {
    nixosModules.default = import ./module.nix;
    configPathsNeeded =
      builtins.fromJSON (builtins.readFile ./config-paths-needed.json);
    meta = { lib, ... }: {
      spModuleSchemaVersion = 1;
      id = "n8n";
      name = "n8n";
      description = "Fair-code workflow automation platform.";
      svgIcon = builtins.readFile ./icon.svg;
      isMovable = true;
      canBeBackedUp = true;
      isRequired = false;
      backupDescription = "n8n data.";
      systemdServices = [
        "n8n.service"
      ];
      folders = [
        "/var/lib/n8n"
      ];
      license = [
        lib.licenses.sustainableUse
      ];
      homepage = "https://n8n.io";
      sourcePage = "https://github.com/n8n-io/n8n";
      supportLevel = "community";
    };
  };
}
