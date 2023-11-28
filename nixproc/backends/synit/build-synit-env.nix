{ pkgs ? import <nixpkgs> { inherit system; }, system ? builtins.currentSystem
, stateDir ? "/var", runtimeDir ? "${stateDir}/run", logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache", spoolDir ? "${stateDir}/spool"
, lockDir ? "${stateDir}/lock", libDir ? "${stateDir}/lib"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false, callingUser ? null, callingGroup ? null
, extraParams ? { }, exprFile ? null }@args:

let
  processesFun = import exprFile;

  processesFormalArgs = builtins.functionArgs processesFun;

  processesArgs = builtins.intersectAttrs processesFormalArgs
    (args // { processManager = "synit"; } // extraParams);

  preserves-tools = if builtins.hasAttr "preserves-tools" pkgs then
    builtins.trace
    "not using inlined preserves-tools package because it is already in nixpkgs"
    pkgs.preserves-tools
  else
    pkgs.rustPlatform.buildRustPackage rec {
      pname = "preserves-tools";
      version = "4.992.2";
      src = pkgs.fetchCrate {
        inherit pname version;
        hash = "sha256-1IX6jTAH6qWE8X7YtIka5Z4y70obiVotOXzRnu+Z6a0=";
      };
      cargoHash = "sha256-D/ZCKRqZtPoCJ9t+5+q1Zm79z3K6Rew4eyuyDiGVGUs=";
    };

  processes = if exprFile == null then { } else processesFun processesArgs;
in pkgs.runCommand "synit-processes.pr" {
  nativeBuildInputs = [ preserves-tools ];
  env.config_inputs =
    pkgs.lib.strings.concatMapStringsSep " " (builtins.getAttr "pkg")
    (builtins.attrValues processes);
}
# Process the configuration with "preserves-tool"
# to catch syntax errors and for normalization.
''
  find $config_inputs -name '*.pr' | while read f
  do
    preserves-tool convert < "$f" >> "$out" || { echo "failed to process $f"; exit 1; }
  done
''
