{ lib }:

rec {
  /* Generates text-encoded Preserves from an arbitrary value.

     Records are generated for lists with a final element in
     the form of `{ record = «label»; }`.

     Type: toPreserves :: a -> string

     Example:
       toPreserves { } [{ a = 0; b = 1; } "c" [ true false ] { record = "foo"; }]
       => "<foo { a: 0 b: 1 } \"c\" [ #t #f ]>"
  */
  toPreserves = { }@args:
    let
      toPreserves' = toPreserves args;
      concatItems = toString;
      mapToSeq = lib.strings.concatMapStringsSep " " toPreserves';
      recordLabel = list:
        with builtins;
        let len = length list;
        in if len == 0 then
          null
        else
          let end = elemAt list (len - 1);
          in if (lib.isAttrs end) && (attrNames end) == [ "record" ] then
            end
          else
            null;
      stringChecks = {
        inherit (lib) isFloat isInt isString isPath isDerivation;
      };
    in v:
    if builtins.any (f: f v) (builtins.attrValues stringChecks) then
      builtins.toJSON v
    else if lib.isAttrs v then
      "{ ${
        concatItems
        (lib.attrsets.mapAttrsToList (key: val: "${key}: ${toPreserves' val}")
          v)
      } }"
    else if lib.isList v then
      let label = recordLabel v;
      in if label == null then
        "[ ${mapToSeq v} ]"
      else
        "<${label.record} ${mapToSeq (lib.lists.init v)}>"
    else if lib.isBool v then
      (if v then "#t" else "#f")
    else if v == null then
      "<null>"
    else if lib.isFunction v then
      toString v # failure
    else
      abort "cannot coerce the value ${v} to Preserves";
}
