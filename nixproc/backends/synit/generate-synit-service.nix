{ stdenv, lib, execline, writeTextFile }:

{ name, description, initialize, daemon, daemonArgs, instanceName, pidFile
, foregroundProcess, foregroundProcessArgs, path, environment, directory, umask
, nice, user, dependencies, credentials, overrides, postInstall }:

let
  util = import ../util { inherit lib; };

  generator = import ./preserves-generator.nix { inherit lib; };
  toPreserves = generator.toPreserves { };

  escapeArgs = args:
    lib.concatMapStringsSep " "
    (arg: ''"${lib.replaceStrings [ ''"'' ] [ ''\"'' ] (toString arg)}"'') args;

  processSpec = {
    argv = "${daemon} ${toString daemonArgs}";
    env = environment;
  } // (lib.attrsets.optionalAttrs (directory != null) { dir = directory; });

in writeTextFile {
  name = "services-${name}";
  destination = "/services/${name}.pr";
  text = ''
    <metadata <daemon ${name}> { description: "${description}" }>
    <require-service <daemon ${name}>>
    <daemon ${name} ${toPreserves processSpec}>
  '';
}
