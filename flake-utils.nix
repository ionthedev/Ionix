{
  lib = {
    eachDefaultSystem = systems: f:
      let
        op = attrs: system: attrs // {
          ${system} = f system;
        };
      in
        builtins.foldl' op { } systems;
  };
}
