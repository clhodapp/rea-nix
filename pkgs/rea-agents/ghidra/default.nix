# SPDX-License-Identifier: MIT
#
# The Ghidra that rea-agents closes over. REA 6.8.0 accepts only Ghidra
# 12.1.x, and its bridge is verified against 12.1.4. When the nixpkgs
# `ghidra` is on the 12.1 line, rea-agents takes it as it is. When
# nixpkgs has moved past 12.1, this file builds that same derivation
# from the 12.1.4 source.
#
# The nixpkgs derivation for 12.2 does not apply to the 12.1.4 source
# as it stands. Two of its four patches and its Gradle dependency lock
# changed with 12.2, and it builds with Gradle 9 on JDK 25. The patches
# and the lock here are the ones nixpkgs carried for 12.1.4, at nixpkgs
# commit 0bb2eedc20e4739f29e8045034f2828ad7054f8f
# (pkgs/tools/security/ghidra, MIT). That derivation built 12.1.4 with
# Gradle 8 on JDK 21, and so does this one.
#
# nixpkgs also packages the release archive as `ghidra-bin`, but the
# archive's native decompiler crashes when it starts, so REA cannot
# decompile with it.
#
# REA's main branch accepts every 12.x release from 12.1 on. Once a REA
# release carries that, rea-agents can take the nixpkgs `ghidra` again,
# and this directory goes.
{
  lib,
  fetchFromGitHub,
  ghidra,
  gradle_8,
  openjdk21,
}:
if lib.versions.majorMinor ghidra.version == "12.1" then
  ghidra
else
  ghidra.overrideAttrs (previous: {
    version = "12.1.4";
    src = fetchFromGitHub {
      owner = "NationalSecurityAgency";
      repo = "Ghidra";
      rev = "Ghidra_12.1.4_build";
      hash = "sha256-EeB3wHE2fbGhvC9Aik83ekGoeXxaA5ZWBSvRi9qLRQc=";
      # The same as nixpkgs: the build reads the commit and its date
      # from these files.
      leaveDotGit = true;
      postFetch = ''
        cd "$out"
        git rev-parse HEAD > $out/COMMIT
        date -u -d "@$(git log -1 --pretty=%ct)" "+%Y-%b-%d" > $out/COMMIT_DATE
        date -u -d "@$(git log -1 --pretty=%ct)" "+%Y%m%d" > $out/COMMIT_DATE_SHORT
        find "$out" -name .git -print0 | xargs -0 rm -rf
      '';
    };
    patches = [
      ./0001-Use-protobuf-gradle-plugin.patch
      ./0002-Load-nix-extensions.patch
      ./0003-Remove-build-datestamp.patch
      ./0004-Remove-help-timestamps.patch
    ];
    nativeBuildInputs = map (
      input: if lib.getName input == "gradle" then gradle_8 else input
    ) previous.nativeBuildInputs;
    mitmCache = gradle_8.fetchDeps {
      pname = "ghidra";
      data = ./deps.json;
    };
    gradleFlags = [ "-Dorg.gradle.java.home=${openjdk21}" ];
  })
