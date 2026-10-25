# SPDX-License-Identifier: MIT
#
# Kuna, a Rust port of the Ghidra decompiler that REA can use as a
# native provider (`--provider kuna`). Upstream's release build runs
# in two phases over one tree: it builds the SLEIGH compiler
# `slacomp`, compiles every processor spec under `specs/`, and then
# builds the `kuna` CLI with the compiled specs embedded.
#
# REA counts a Kuna as verified only when `kuna --version` prints
# exactly the version it was tested with, which upstream bakes in from
# `KUNA_VERSION` at build time. REA also refuses a `kuna` that is a
# script, so the binary is installed as built, without a wrapper.
{
  lib,
  fetchFromGitHub,
  python3,
  rustPlatform,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "kuna";
  version = "1.833";

  src = fetchFromGitHub {
    owner = "Noelo-Lab";
    repo = "kuna";
    tag = "v${finalAttrs.version}";
    hash = "sha256-adJONwYWLr9JjuXRbw4nms06R0v/6EyhzpfzRodlTGk=";
  };

  cargoRoot = "decompiler";
  buildAndTestSubdir = "decompiler";
  cargoHash = "sha256-K33ivuxMOZQz/n3NusQyM7EV8brCzPxwEI+blrsF4GU=";

  env.KUNA_VERSION = finalAttrs.version;

  # Phase one: the SLEIGH compiler, built for the build machine, then
  # every spec compiled in place, where the CLI's build script embeds
  # them.
  preBuild = ''
    (cd decompiler && cargo build --offline --release -j "$NIX_BUILD_CORES" \
      --package kuna-slacomp --target-dir "$NIX_BUILD_TOP/slacomp")
    "$NIX_BUILD_TOP/slacomp/release/slacomp" -a specs
  '';

  cargoBuildFlags = [
    "--package"
    "kuna-cli"
    "--features"
    "kuna-cli/embed-specs"
  ];
  # The unit tests of the CLI. Its integration tests need upstream's
  # whole development setup: the workspace's other binaries
  # (`decomp_dbg`, the console), gcc and an ARM cross gcc compiling
  # with `-Werror`, and fixture executables committed to the repository
  # for an FHS dynamic loader.
  cargoTestFlags = [
    "--package"
    "kuna-cli"
    "--features"
    "kuna-cli/embed-specs"
    "--bins"
  ];
  # The call-graph tests generate their ARM fixtures with a Python
  # script.
  nativeCheckInputs = [ python3 ];

  meta = {
    description = "Decompiler for ELF and Mach-O executables, a Rust port of the Ghidra decompiler";
    homepage = "https://github.com/Noelo-Lab/kuna";
    license = lib.licenses.asl20;
    mainProgram = "kuna";
    platforms = lib.platforms.linux;
  };
})
