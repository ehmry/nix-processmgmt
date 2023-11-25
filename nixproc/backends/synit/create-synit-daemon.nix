{ lib, writeTextFile, toPreserves }:

{ name, description, daemon, daemonArgs, environment, directory
# List of services that this configuration depends on.
, dependencies ? [ ]
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

  serviceName = "<daemon ${name}>";

in writeTextFile {
  name = "services-${name}";
  destination = "/services/${name}.pr";
  text = ''
    <metadata ${serviceName} { description: "${description}" }>
  ''

    + (lib.strings.optionalString require-service ''
      <require-service ${serviceName}>
    '')

    + (lib.strings.concatMapStrings (dep: ''
      <depends-on ${serviceName} ${dep}>
    '') depends-on)

    + (lib.strings.concatMapStrings (pkg: ''
      <depends-on ${serviceName} ${pkg.serviceName}>
    '') dependencies)

    + ''
      <daemon ${name} ${toPreserves processSpec}>
    '';
} // {
  inherit serviceName;
}
