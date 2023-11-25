{ lib, createSynitDaemon, undaemonize }:

{ name, description, initialize, daemon, daemonArgs, instanceName, pidFile
, foregroundProcess, foregroundProcessArgs, path, environment, directory, umask
, nice, user, dependencies, credentials, overrides, postInstall }:

let
  generatedTargetSpecificArgs = {
    inherit name description environment directory dependencies;

    argv = if foregroundProcess != null then
      [ foregroundProcess ] ++ foregroundProcessArgs
    else
      [ "${undaemonize}/bin/undaemonize" daemon ] ++ daemonArgs;
  };

  targetSpecificArgs = if builtins.isFunction overrides then
    overrides generatedTargetSpecificArgs
  else
    lib.recursiveUpdate generatedTargetSpecificArgs overrides;
in createSynitDaemon targetSpecificArgs
