{ lib, busybox, runtimeShell, writeScript, writeTextFile, undaemonize }:

rec {
  util = import ../util { inherit lib; };

  inherit (import ./util.nix { inherit lib; }) toPreserves;

  createSynitDaemon = import ../../backends/synit/create-synit-daemon.nix {
    inherit lib busybox runtimeShell writeScript writeTextFile;
    inherit toPreserves util;
  };

  generateSynitService =
    import ../../backends/synit/generate-synit-service.nix {
      inherit lib createSynitDaemon undaemonize;
    };
}
