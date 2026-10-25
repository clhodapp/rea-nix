# SPDX-License-Identifier: MIT
#
# The default package overlay: the REA packages under `pkgs.rea-nix`
# (pkgs/default.nix lists them), built from the sources this flake
# pins. A consumer that lists this flake in `projects` holds it as
# `rea-nix/default`, which its package sets apply by default. The scope
# name is bound here, so the packages land under `pkgs.rea-nix` in any
# consumer.
#
# The package tree stays at pkgs/: the update workflow diffs and commits
# each `pkgs/<package>` as it moves a pin.
{ closure-inputs, closure-lib, ... }:
{
  overlay = closure-lib.caisson.nixpkgs.mkPackagesOverlay (
    { callPackage, lib, ... }:
    import ../../pkgs {
      inherit callPackage lib;
      inputs = closure-inputs;
    }
  ) "rea-nix";
}
