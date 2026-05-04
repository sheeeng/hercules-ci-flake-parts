{
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({ withSystem, ... }: {
      systems = [ ];
      perSystem = { system, ... }:
        builtins.trace "Evaluating perSystem for ${system}" { };
      flake.result =
        let
          a = withSystem "foo" ({ config, ... }: null);
          b = withSystem "foo" ({ config, ... }: "ok");
        in
        builtins.seq a b;
    });
}
