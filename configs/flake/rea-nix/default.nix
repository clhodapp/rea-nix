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
            # Each package carries its smoke test; `smoke-<package>` is
            # how update.yml names the one it runs against a bump.
            checks =
              pkgs.lib.mapAttrs' (name: package: pkgs.lib.nameValuePair "smoke-${name}" package.tests.smoke)
                {
                  inherit (packages) rea-agents claude-code-plugin;
                };
            treefmt.programs.nixfmt.enable = true;
          };
      };
  };

}
