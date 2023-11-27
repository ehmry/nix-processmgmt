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
    pkgs.lib.strings.concatMapStringsSep " " (builtins.getAttr "pkg") (builtins.attrValues processes);
} ''
  cat $(find $config_inputs -name '*.pr') | preserves-tool convert > "$out"
''
