# SPDX-License-Identifier: MIT
{ callPackage, ... }:
{
  rea-agents = callPackage ./rea-agents { };
  claude-code-plugin = callPackage ./claude-code-plugin { };
}
