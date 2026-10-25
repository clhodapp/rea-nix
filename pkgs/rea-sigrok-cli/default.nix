# SPDX-License-Identifier: MIT
#
# sigrok-cli at the release REA's signal-recording decoder requires:
# REA runs `sigrok-cli --version` and accepts only a banner starting
# `sigrok-cli 0.7.2`. nixpkgs carries a later snapshot of the 0.8
# line, so this overrides it to the 0.7.2 release tarball, which
# builds against the nixpkgs libsigrok and libsigrokdecode.
{
  fetchurl,
  sigrok-cli,
}:
sigrok-cli.overrideAttrs (
  finalAttrs: _: {
    version = "0.7.2";
    src = fetchurl {
      url = "https://sigrok.org/download/source/sigrok-cli/sigrok-cli-${finalAttrs.version}.tar.gz";
      hash = "sha256-cdBEPzaJe/Vlcy3sIGgw2+oPJ4m2YBzxBTayhtEUCrg=";
    };
  }
)
