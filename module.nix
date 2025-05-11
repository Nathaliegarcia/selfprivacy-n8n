{ config, lib, ... }:
let
  # Just a shorthand for the config
  sp = config.selfprivacy;
  cfg = sp.modules.n8n;
in
{
  options.selfprivacy.modules.n8n = {
    # We are required to add an enable option.
    enable = (lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Enable n8n";
    }) // {
      meta = {
        type = "enable";
      };
    };
    location = (lib.mkOption {
      type = lib.types.str;
      description = "n8n location";
    }) // {
      meta = {
        type = "location";
      };
    };
    subdomain = (lib.mkOption {
      default = "n8n";
      type = lib.types.strMatching "[A-Za-z0-9][A-Za-z0-9\-]{0,61}[A-Za-z0-9]";
      description = "Subdomain";
    }) // {
      meta = {
        widget = "subdomain";
        type = "string";
        regex = "[A-Za-z0-9][A-Za-z0-9\-]{0,61}[A-Za-z0-9]";
        weight = 0;
      };
    };
    # TODO: Re-enable after SP migrates to 24.11
     enableTaskRunners = (lib.mkOption {
       default = true;
       type = lib.types.bool;
       description = "Enable task runners";
     }) // {
       meta = {
         type = "bool";
         weight = 1;
       };
     };
####################################
  };

  config = lib.mkIf cfg.enable {

    # n8n is unfree, so we need to allow it
    nixpkgs.config.allowUnfree = true;

    fileSystems = lib.mkIf sp.useBinds {
      "/var/lib/private/n8n" = {
        device = "/volumes/${cfg.location}/n8n";
        options = [ "bind" ];
      };
    };

    users = {
      users.n8n = {
        isSystemUser = true;
        group = "n8n";
      };
      groups.n8n = {};
    };

    services = {
      n8n = {
        enable = true;
        webhookUrl = "https://${cfg.subdomain}.${sp.domain}"; #This was added so that OAuth redirect to the server url
        settings = {
          host = "${cfg.subdomain}.${sp.domain}";
          port = 5678;
          listen_address = "127.0.0.1";
          generic = {
            timezone = sp.timezone;
            # TODO: Re-enable after SP migrates to 24.11
            releaseChannel = "stable";
          };
          database = {
            type = "postgresdb";
            postgresdb = {
              database = "n8n";
              host = "/run/postgresql";
              user = "n8n";
            };
          };
          # TODO: Re-enable after SP migrates to 24.11
           taskRunners = {
             enabled = cfg.enableTaskRunners;
           };
################################################
          versionNotifications = {
            enabled = false;
          };
        };
      };
      postgresql = {
        ensureDatabases = [
          "n8n"
        ];
        ensureUsers = [
          {
            name = "n8n";
            ensureDBOwnership = true;
          }
        ];
      };
    };

    systemd = {
      services.n8n = {
 
        environment = {
          N8N_PUSH_BACKEND = "websocket";   # or "sse" 
          # WEBHOOK_URL= lib.mkForce "https://${cfg.subdomain}.${sp.domain}";
          N8N_EDITOR_BASE_URL = lib.mkForce "https://${cfg.subdomain}.${sp.domain}";
          N8N_HOST            = "${cfg.subdomain}.${sp.domain}";
          N8N_PROTOCOL        = "https";   

        };

        unitConfig.RequiresMountsFor = lib.mkIf sp.useBinds "/volumes/${cfg.location}/n8n";
        serviceConfig = {
          Slice = "n8n.slice";
          DynamicUser = lib.mkForce "false";
          User = "n8n";
          Group = "n8n";
        };
      };
      slices.n8n = {
        description = "n8n service slice";
      };
    };

    services.nginx.virtualHosts."${cfg.subdomain}.${sp.domain}" = {
      useACMEHost = sp.domain;
      forceSSL = true;
      extraConfig = ''
        add_header Strict-Transport-Security $hsts_header;
        #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;
        add_header 'Referrer-Policy' 'origin-when-cross-origin';
        add_header X-Frame-Options SAMEORIGIN;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
      '';
      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:5678";
          proxyWebsockets = true;        # Added for websocket support
          extraConfig = ''
            proxy_read_timeout  60s;     # Added for websocket support
            proxy_send_timeout  60s;     # Added for websocket support
          '';
        };
      };
    };
  };
}
