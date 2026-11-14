# SPDX-License-Identifier: MIT
#
# The checks of rea-nix: a flake-parts configuration declared inside the
# flake-parts caisson top (configs/flake/rea-nix), whose dependencies
# are those of the caisson top with the pins of tests/dependencies
# beside them. The caisson top gathers the checks declared here into
# its `checks` output. A flake that lists rea-nix as an input reads
# nothing of this configuration, so it locks none of the pins of
# tests/dependencies.
{ ... }:
{ inputs, lib, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      # Duplicated in the formatter partition of configs/flake/rea-nix:
      # the partition and this configuration are separate evaluations.
      treefmt.programs.nixfmt.enable = true;

      # Every test a package carries, as `<test>-<package>`: the names
      # update.yml runs against a bump.
      caisson.checks = {
        treefmt = {
          category = "format";
          description = "the Nix files are formatted with nixfmt";
        };
      }
      //
        lib.concatMapAttrs
          (
            name: package:
            lib.mapAttrs' (
              test: derivation:
              lib.nameValuePair "${test}-${name}" {
                inherit derivation;
                category = "build";
                description = "the test `${test}` of the package `${name}` passes";
              }
            ) package.tests
          )
          {
            inherit (pkgs.rea-nix) rea-agents rea-agents-minimal reverse-engineer-anything;
          };
    };
}
