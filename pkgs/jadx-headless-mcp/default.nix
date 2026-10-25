# SPDX-License-Identifier: MIT
#
# jadx-headless-mcp, the JADX engine REA's Android provider drives: a
# Kotlin MCP server around JADX 1.5.6, built as the one fat JAR REA
# loads from `REA_JADX_MCP_JAR`. REA checks the JAR for the jadx-
# headless-mcp, JADX, Gson and MCP SDK classes, so it must be upstream's
# `shadowJar` output.
#
# The source is the commit REA audited for 0.7.1. Upstream later
# rewrote its history, and its `v0.7.1` tag now points at another
# commit with the same tree. REA reports a JAR whose SHA-256 differs
# from upstream's release artifact as unaudited; a build from source on
# another JDK always differs.
#
# Gradle runs on JDK 17, the toolchain the build asks for, so it finds
# the toolchain without downloading one. Its dependencies come from the
# lockfile `deps.json`, which the update script writes.
{
  lib,
  fetchFromGitHub,
  gradle_9,
  jdk17,
  stdenvNoCC,
}:
let
  gradle = gradle_9.override { java = jdk17; };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "jadx-headless-mcp";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "1013503897";
    repo = "jadx-headless-mcp";
    rev = "5844800a486d2248fa949b74c9896285f5b54de2";
    hash = "sha256-mCi6lt4HGqDSTtdcGEP0AoOYU9KHfdbSg7yXJn4a378=";
  };

  nativeBuildInputs = [ gradle ];

  mitmCache = gradle.fetchDeps {
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
  };

  gradleBuildTask = "shadowJar";
  gradleFlags = [ "-Dfile.encoding=utf-8" ];

  doCheck = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 build/libs/jadx-headless-mcp-${finalAttrs.version}-all.jar \
      $out/share/java/jadx-headless-mcp.jar
    runHook postInstall
  '';

  meta = {
    description = "Headless JADX decompiler as an MCP server, built as the JAR REA loads";
    homepage = "https://github.com/1013503897/jadx-headless-mcp";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode
    ];
    platforms = lib.platforms.unix;
  };
})
