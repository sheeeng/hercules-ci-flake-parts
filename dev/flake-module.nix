{ config, lib, inputs, self, withSystem, ... }:

{
  imports = [
    inputs.pre-commit-hooks-nix.flakeModule
    inputs.hercules-ci-effects.flakeModule # herculesCI attr
    inputs.nix-unit.modules.flake.default
  ];
  systems = [ "x86_64-linux" "aarch64-darwin" ];

  hercules-ci.flake-update = {
    enable = true;
    autoMergeMethod = "merge";
    when.dayOfMonth = 1;
    flakes = {
      "." = { };
      "dev" = { };
    };
  };

  perSystem = { config, pkgs, ... }: {

    devShells.default = pkgs.mkShell {
      nativeBuildInputs = [
        config.nix-unit.package
        pkgs.nixpkgs-fmt
        pkgs.hci
      ];
      shellHook = ''
        ${config.pre-commit.shellHook}
      '';
    };

    pre-commit = {
      inherit pkgs; # should make this default to the one it can get via follows
      settings = {
        hooks.nixpkgs-fmt.enable = true;
      };
    };

    checks.eval-tests =
      let tests = import ./tests/eval-tests.nix { flake-parts = self; };
      in tests.runTests pkgs.emptyFile // { internals = tests; };

    checks.perSystem-memoize = pkgs.callPackage ./tests/perSystem-memoize.nix {
      flake-parts = self;
    };

    nix-unit.tests = import ./tests/nix-unit.nix { flake-parts = self; };

    # nix-unit evaluates the flake, which triggers the dev partition via
    # flake-compat, requiring network to fetch dev inputs.
    nix-unit.allowNetwork = true;

  };
  flake = {
    # for repl exploration / debug
    config.config = config;
    options.mySystem = lib.mkOption { default = config.allSystems.${builtins.currentSystem}; };
    config.effects = withSystem "x86_64-linux" ({ pkgs, hci-effects, ... }: {
      tests = {
        template = pkgs.callPackage ./tests/template.nix { inherit hci-effects; };
      };
    });
  };
}
