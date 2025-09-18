{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.rapid7;
  defaultSpaceDir = "/opt/rapid7";
  version = "4.0.18.46";
in
{
  options = {
    services.rapid7 = {
      enable = lib.mkEnableOption "";

      confOptions = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "";
        description = ''
        '';
      };

    };
  };

  config = lib.mkIf cfg.enable {
    # Use the derivation directly to install Rapid7 agent
    system.activationScripts.installRapid7 = ''
        # Check if the directory already exists and has content
        if [ -d "${defaultSpaceDir}" ] && [ "$(ls -A ${defaultSpaceDir} 2>/dev/null)" ]; then
          echo ">> ${defaultSpaceDir} already exists and contains files. Skipping installation."
        else
          echo ">> Installing Rapid7 Insight Agent to ${defaultSpaceDir}"

          # Create the destination directory
          mkdir -p ${defaultSpaceDir}

          # Copy files from the derivation
          if [ -d "${pkgs.callPackage ./default.nix {}}/opt/rapid7" ]; then
            echo ">> Copying Rapid7 files from derivation..."
            cp -rf ${pkgs.callPackage ./default.nix {}}/opt/rapid7/* ${defaultSpaceDir}/
            chmod -R 755 ${defaultSpaceDir}
            chown -R root:root ${defaultSpaceDir}
            echo ">> Rapid7 Insight Agent installation completed"
          else
            echo ">> Error: Rapid7 directory not found in derivation"
            exit 1
          fi
        fi
    '';

    systemd.services.ir_agent = {
      description = "Rapid7 Insight Agent";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${defaultSpaceDir}/ir_agent/components/insight_agent/${version}/ir_agent ${cfg.confOptions}";
        Restart = "on-failure";
        RestartSec = "2min";
        KillMode = "process";
        KillSignal = "SIGINT";
        User = "root";
        Group = "root";
        WorkingDirectory = "${defaultSpaceDir}";
      };
    };
  };

  meta = {
    maintainers = with lib.maintainers; [ Caspersonn ];
  };
}
