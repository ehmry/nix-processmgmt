{ lib }:

let inherit (lib) isAttrs isBool isFunction isList;
in rec {
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
      recordLabel = list:
        with builtins;
        let len = length list;
        in if len == 0 then
          null
        else
          let end = elemAt list (len - 1);
          in if (isAttrs end) && (attrNames end) == [ "record" ] then
            end
          else
            null;
    in v:
    if isAttrs v then
      "{ ${
        concatItems
        (lib.attrsets.mapAttrsToList (key: val: "${key}: ${toPreserves' val}")
          v)
      } }"
    else if isList v then
      let label = recordLabel v;
      in if label == null then
        "[ ${concatItems (map toPreserves' v)} ]"
      else
        "<${label.record} ${concatItems (map toPreserves' (lib.lists.init v))}>"
    else if isBool v then
      (if v then "#t" else "#f")
    else if isFunction v then
      abort "generators.toPreserves: cannot convert a function to Preserves"
    else if isNull v then
      "null"
    else
      builtins.toJSON v;
}
