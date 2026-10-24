# SPDX-License-Identifier: MIT
{ ... }:
{

  overlay = final: prev: {
    rea-nix = prev.rea-nix or { };
  };

}
