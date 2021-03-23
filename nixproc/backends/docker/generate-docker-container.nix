{ createDockerContainer, dockerTools, stdenv, lib, writeTextFile, findutils, glibc, dysnomia, basePackages, runtimeDir, stateDir, forceDisableUserChange, createCredentials }:

{ name
, description
, initialize
, daemon
, daemonArgs
, instanceName
, pidFile
, foregroundProcess
, foregroundProcessArgs
, path
, environment
, directory
, umask
, nice
, user
, dependencies
, credentials
, overrides
, postInstall
}:

# TODO:
# umask unsupported
# nice unsupported

let
  util = import ../util {
    inherit lib;
  };

  commonTools = (import ../../../tools {}).common;

  generateForegroundProxy = import ../util/generate-foreground-proxy.nix {
    inherit stdenv lib writeTextFile;
  };

  _user = util.determineUser {
    inherit user forceDisableUserChange;
  };

  cmd = if foregroundProcess != null
    then
      if initialize == ""
      then [ foregroundProcess ] ++ foregroundProcessArgs
      else
        let
          wrapper = generateForegroundProxy ({
            wrapDaemon = false;
            executable = foregroundProcess;
            user = _user;
            inherit name initialize runtimeDir stdenv;
          } // lib.optionalAttrs (instanceName != null) {
            inherit instanceName;
          } // lib.optionalAttrs (pidFile != null) {
            inherit pidFile;
          });
        in
        [ wrapper ] ++ foregroundProcessArgs
    else
      let
        wrapper = generateForegroundProxy ({
          wrapDaemon = true;
          executable = daemon;
          user = _user;
          inherit name runtimeDir initialize stdenv;
        } // lib.optionalAttrs (instanceName != null) {
          inherit instanceName;
        } // lib.optionalAttrs (pidFile != null) {
          inherit pidFile;
        });
      in
      [ wrapper ] ++ daemonArgs;

  # Remove the Nix store references so that these Nix store paths won't end up in the image.
  # Instead, we mount the host system's Nix store so that the software is still accessible inside the container.
  cmdWithoutContext = map (arg: if builtins.isAttrs arg then builtins.unsafeDiscardStringContext arg else toString arg) cmd;

  _environment = util.appendPathToEnvironment {
    inherit environment;
    path = basePackages ++ path ++ [ "/" ]; # Also give permission to /bin to allow any package added to contents can be used
  };

  credentialsSpec = createCredentials credentials;

  generatedDockerImageArgs = {
    inherit name;
    tag = "latest";

    runAsRoot = import ../docker/setup.nix {
      inherit dockerTools commonTools lib dysnomia findutils glibc stateDir runtimeDir forceDisableUserChange credentialsSpec;
    };

    config = {
      Cmd = cmdWithoutContext;
    } // lib.optionalAttrs (_environment != {}) {
      Env = map (varName: "${varName}=${toString (builtins.getAttr varName _environment)}") (builtins.attrNames _environment);
    } // lib.optionalAttrs (directory != null) {
      WorkingDir = directory;
    } // lib.optionalAttrs (_user != null && initialize == "") {
      User = _user;
    };
  };

  dockerImageArgs =
    if overrides ? image
    then
      if builtins.isFunction overrides.image then overrides.image generatedDockerImageArgs
      else lib.recursiveUpdate generatedDockerImageArgs overrides.image
    else generatedDockerImageArgs;

  dockerImage = dockerTools.buildImage dockerImageArgs;

  generatedDockerContainerArgs = {
    inherit name dockerImage postInstall cmd dependencies;
    dockerImageTag = "${name}:latest";
    useHostNixStore = true;
    useHostNetwork = true;
    mapStateDirVolumes = [ stateDir ];
  };

  dockerContainerArgs =
    if overrides ? container
    then
      if builtins.isFunction overrides.container then overrides.container generatedDockerContainerArgs
      else lib.recursiveUpdate generatedDockerContainerArgs overrides.container
    else generatedDockerContainerArgs;
in
createDockerContainer dockerContainerArgs
