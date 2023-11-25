{ lib, writeTextFile, toPreserves }:

{ name, description, daemon, daemonArgs, environment, directory
# Daemon will not be started until all elements of depends-on are asserted.
# Example: [ "<service-state <milestone network> up>" ]
, depends-on ? [ ]
  # Whether the daemon shall be declared as required.
, require-service ? true }:

let
  #quoteArgs =
  #  map (arg: ''"${lib.replaceStrings [ ''"'' ] [ ''\"'' ] (toString arg)}"'');

  processSpec = {
    argv = [ daemon ] ++ daemonArgs;
    env = environment;
  } // (lib.attrsets.optionalAttrs (directory != null) { dir = directory; });

in writeTextFile {
  name = "services-${name}";
  destination = "/services/${name}.pr";
  text = let daemonName = "<daemon ${name}>";
  in ''
    <metadata ${daemonName} { description: "${description}" }>
    <daemon ${name} ${toPreserves processSpec}>
  ''

  + (lib.strings.optionalString require-service ''
    <require-service ${daemonName}>
  '')

  + (lib.strings.concatMapStrings (dep: ''
    <depends-on ${daemonName} ${dep}>
  '') depends-on);
}
