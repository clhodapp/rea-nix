# SPDX-License-Identifier: MIT
{ callPackage, ... }:
{
  rea-agents = callPackage ./rea-agents { };
  reverse-engineer-anything = callPackage ./reverse-engineer-anything { };
}
