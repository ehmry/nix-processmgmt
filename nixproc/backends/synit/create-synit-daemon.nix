{ lib, busybox, runtimeShell, toPreserves, writeScript, writeTextFile }:

{ name, description, argv, environment, directory, path
# Shell instructions that specify how the state of the process should be initialized.
, initialize ? ""
  # List of services that this configuration depends on.
, dependencies ? [ ]
  # Daemon will not be started until all elements of depends-on are asserted.
  # Example: [ "<service-state <milestone network> up>" ]
, depends-on ? [ ]
  # Whether the daemon shall be declared as required.
, require-service ? true }:

let
  env = environment // {
    PATH = lib.strings.makeBinPath (path ++ [ busybox ]);
  };

  processSpec = {
    inherit argv env;
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

    + (lib.strings.optionalString (initialize != "") (let
      # TODO: depend the initialization on other dependencies?
      initializeName = "initialize-${name}";
      script = writeScript "${initializeName}.sh" ''
        #!${runtimeShell}
        ${initialize}
      '';
    in ''
      <depends-on ${serviceName} <service-state <daemon ${initializeName}> complete>>
      <daemon ${initializeName} {
        argv: [ "${script}" ]
        env: ${toPreserves env}
        readyOnStart: #f
        restart: on-error
      }>
    ''))

    + ''
      <daemon ${name} ${toPreserves processSpec}>
    '';
} // {
  inherit serviceName;
}
