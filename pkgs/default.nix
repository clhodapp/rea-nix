# SPDX-License-Identifier: MIT
{ callPackage, lib, ... }:
let
  rea-agents = callPackage ./rea-agents { };
  # REA with its core dependencies only: no analysis engine and no
  # external tool.
  rea-agents-minimal = rea-agents.override (lib.mapAttrs (_: _: null) rea-agents.tools);
in
{
  inherit rea-agents rea-agents-minimal;
  # The skill is the same in both; copying it from the minimal package
  # keeps the engines out of its build.
  reverse-engineer-anything = callPackage ./reverse-engineer-anything {
    rea-agents = rea-agents-minimal;
  };
}
