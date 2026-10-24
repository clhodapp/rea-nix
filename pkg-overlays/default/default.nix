# SPDX-License-Identifier: MIT
#
# The default package overlay: the REA packages under `pkgs.rea-nix`.
# A consumer that lists this flake in `projects` holds it as
# `rea-nix/default`, which its package sets apply by default. The scope
# name is bound here, so the packages land under `pkgs.rea-nix` in any
# consumer.
#
# The package tree stays at pkgs/: the update workflow diffs and commits
# each `pkgs/<package>` as it moves a pin.
{ closure-lib, ... }:
{
  overlay = closure-lib.caisson.nixpkgs.mkPackagesOverlay ../../pkgs "rea-nix";
}
