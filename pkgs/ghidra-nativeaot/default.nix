# SPDX-License-Identifier: MIT
#
# REA's Ghidra extension for .NET NativeAOT executables: upstream
# ghidra-nativeaot compiled together with the adapter classes REA keeps
# in `bridge/nativeaot`, into the one JAR REA loads from
# `REA_GHIDRA_NATIVEAOT_JAR`. The steps are those of REA's own
# `scripts/build-ghidra-nativeaot.mjs`, with its checks of the checkout
# and the javac version left to the pinned inputs here.
#
# The extension runs inside REA's Ghidra, so it is compiled against the
# same Ghidra package.
{
  lib,
  fetchFromGitHub,
  findutils,
  ghidra,
  jdk21,
  reaSrc,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "rea-ghidra-nativeaot";
  # The upstream commit REA's adapter records as its source revision.
  version = "0-unstable-2026-05-26";

  src = fetchFromGitHub {
    owner = "Washi1337";
    repo = "ghidra-nativeaot";
    rev = "effeb734fc570c32650f88b159608979dc7b423e";
    hash = "sha256-ZleuiPZYrK9CH2/689iLttbYiFuU12rg6D8myu/ugs4=";
  };

  nativeBuildInputs = [
    findutils
    jdk21
  ];

  buildPhase = ''
    runHook preBuild
    mkdir classes
    find ${ghidra}/lib/ghidra/Ghidra -name '*.jar' | sort | paste -s -d: > classpath
    find src/main/java ${reaSrc}/bridge/nativeaot -name '*.java' | sort > sources
    javac -proc:none --release 21 -cp "$(cat classpath)" -d classes @sources
    cp LICENSE.md classes/LICENSE-ghidra-nativeaot.md
    jar --create --file rea-ghidra-nativeaot.jar --date=2025-01-01T00:00:00Z -C classes .
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 rea-ghidra-nativeaot.jar $out/share/java/rea-ghidra-nativeaot.jar
    runHook postInstall
  '';

  meta = {
    description = "Ghidra extension for .NET NativeAOT executables, built for REA";
    homepage = "https://github.com/Washi1337/ghidra-nativeaot";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
