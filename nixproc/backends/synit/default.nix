{ lib, runtimeShell, writeScript, writeTextFile, undaemonize }:

rec {
  util = import ./util.nix { inherit lib; };

  toPreserves = util.toPreserves { };

  createSynitDaemon = import ../../backends/synit/create-synit-daemon.nix {
    inherit lib runtimeShell writeScript writeTextFile;
    inherit toPreserves;
  };

  generateSynitService =
    import ../../backends/synit/generate-synit-service.nix {
      inherit lib createSynitDaemon undaemonize;
    };
}
