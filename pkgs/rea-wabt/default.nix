# SPDX-License-Identifier: MIT
#
# WABT at the release REA's WebAssembly inspection requires: REA runs
# `wasm-validate`, `wasm-objdump` and `wasm2wat` with `--version` and
# accepts only `1.0.42`. nixpkgs carries 1.0.41. The version banner
# comes from the version the build is configured with, so the override
# goes through `finalAttrs`.
{ wabt }:
wabt.overrideAttrs (
  finalAttrs: previous: {
    version = "1.0.42";
    src = previous.src.override {
      tag = finalAttrs.version;
      hash = "sha256-33XpYt42Jw2xfwBR64jVI3VYVIKD1YjND9SSI6CdkaM=";
    };
  }
)
