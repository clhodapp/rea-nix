# SPDX-License-Identifier: MIT
{
  callPackage,
  inputs,
  lib,
  ...
}:
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

  # Tools REA uses that nixpkgs does not carry.
  ghidra-nativeaot = callPackage ./ghidra-nativeaot { reaSrc = rea-agents-minimal.src; };
  jadx-headless-mcp = callPackage ./jadx-headless-mcp { };
  kuna = callPackage ./kuna { };
  pwndbg = callPackage ./pwndbg { pwndbgFlake = inputs.pwndbg; };
  wakaru = callPackage ./wakaru { };

  # nixpkgs packages at the exact versions REA requires.
  rea-pwntools-python = callPackage ./rea-pwntools-python { };
  rea-sigrok-cli = callPackage ./rea-sigrok-cli { };
  rea-wabt = callPackage ./rea-wabt { };
}
