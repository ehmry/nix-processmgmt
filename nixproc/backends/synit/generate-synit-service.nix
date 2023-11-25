{ lib, createSynitDaemon }:

{ name, description, initialize, daemon, daemonArgs, instanceName, pidFile
, foregroundProcess, foregroundProcessArgs, path, environment, directory, umask
, nice, user, dependencies, credentials, overrides, postInstall }:

let
  generatedTargetSpecificArgs = {
    inherit name description daemon daemonArgs environment directory;
  };

  targetSpecificArgs = if builtins.isFunction overrides then
    overrides generatedTargetSpecificArgs
  else
    lib.recursiveUpdate generatedTargetSpecificArgs overrides;
in createSynitDaemon targetSpecificArgs
