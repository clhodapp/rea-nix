# SPDX-License-Identifier: MIT
#
# Wakaru, the JavaScript unbundler and decompiler REA uses to recover
# readable modules from bundles (`recover-javascript-sources`): the
# native `wakaru` binary of upstream's Rust workspace, built from the
# release tag REA's adapter is verified against. REA accepts ^1.13.0
# and reports any binary other than upstream's release build, by its
# SHA-256, as compatible rather than audited.
{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "wakaru";
  version = "1.14.0";

  src = fetchFromGitHub {
    owner = "pionxzh";
    repo = "wakaru";
    tag = "v${finalAttrs.version}";
    hash = "sha256-HdSrirk4VcWlifK4m97fJbyfXeIhLfzWRWQGPxAd0hI=";
  };

  cargoHash = "sha256-t3LS3nMihmHmRmJ014YkvXYynv4XwtQWn267GAWnLiE=";

  # The CLI crate is the binary REA runs; the workspace also builds a
  # WebAssembly crate for upstream's playground.
  cargoBuildFlags = [
    "--package"
    "wakaru-cli"
  ];
  cargoTestFlags = [
    "--package"
    "wakaru-cli"
  ];

  meta = {
    description = "JavaScript unbundler and decompiler for modern frontend bundles";
    homepage = "https://github.com/pionxzh/wakaru";
    license = lib.licenses.asl20;
    mainProgram = "wakaru";
    platforms = lib.platforms.linux;
  };
})
