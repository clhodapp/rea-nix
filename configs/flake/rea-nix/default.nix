# SPDX-License-Identifier: MIT
{ ... }:
{
  config,
  inputs,
  lib,
  ...
}:
{

  imports = [ inputs.flake-parts.flakeModules.partitions ];

  debug = false;
  caisson = {
    libOverlays.exported = libOverlays: {
      inherit (libOverlays) default;
    };

    # The REA packages are the `default` entry of this flake's package
    # overlay registry (pkg-overlays/, registered on mkLib): the package
    # set applies it by default, and the flake exports it as `pkgOverlays`
    # and as the plain `overlays.default`.
    nixpkgs = {
      packages.export.enabled = true;
    };
  };

  perSystem =
    { config, ... }:
    {
      packages.default = config.packages.rea-agents;
    };

  partitionedAttrs.checks = "checks";
  partitionedAttrs.formatter = "formatter";

  partitions.formatter = {
    extraInputs = (lib.caisson.pins.flake-compat ../../../tests/dependencies).sources;
    module =
      { inputs, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem.treefmt.programs.nixfmt.enable = true;
      };
  };

  partitions.checks = {
    extraInputs = (lib.caisson.pins.flake-compat ../../../tests/dependencies).sources;
    module =
      { inputs, self, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem =
          { pkgs, system, ... }:
          let
            packages = self.packages.${system};
          in
          {
            # Every test a package carries, as `<test>-<package>`: the
            # names update.yml runs against a bump.
            checks = pkgs.lib.concatMapAttrs (
              name: package: pkgs.lib.mapAttrs' (test: pkgs.lib.nameValuePair "${test}-${name}") package.tests
            ) { inherit (packages) rea-agents rea-agents-minimal reverse-engineer-anything; };
            treefmt.programs.nixfmt.enable = true;
          };
      };
  };

}
