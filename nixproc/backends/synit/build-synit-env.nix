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

  processes = if exprFile == null then { } else processesFun processesArgs;
in pkgs.runCommand "synit-processes.pr" {
  nativeBuildInputs = [ pkgs.preserves-tools ];
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
