{ lib, pkgs, ... }:

let
  syndicate-server = pkgs.syndicate-server or (let
    repo = builtins.fetchTarball
      "https://git.syndicate-lang.org/ehmry/syndicate-flake/archive/trunk.tar.gz";
    pkgs' = import repo { inherit pkgs; };
  in pkgs'.syndicate-server);

  synit = pkgs.fetchFromGitea {
    domain = "git.syndicate-lang.org";
    owner = "synit";
    repo = "synit";
    rev = "a2ecd8a4e441f8622a57a99987cb0aa5be9e1dcd";
    hash = "sha256-M79AJ8/Synzm4CYkt3+GYViJLJcuYBW+x32Vfy+oFUM=";
  };

in {
  systemd.services.syndicate-server = {
    description = "Syndicate dataspace server";
    wantedBy = [ "basic.target" ];
    preStart = ''
      mkdir -p "/etc/syndicate/services"
      ${lib.getExe pkgs.rsync} -r \
        --exclude 001-console-getty.pr \
        --exclude configdirs.pr \
        --exclude eudev.pr \
        --exclude hostname.pr \
        --exclude services \
        "${synit}/packaging/packages/synit-config/files/etc/syndicate/" \
        "/etc/syndicate"
    '';
    serviceConfig = {
      ExecStart =
        "${lib.getExe syndicate-server} --no-banner --config /etc/syndicate";
    };
  };
}
