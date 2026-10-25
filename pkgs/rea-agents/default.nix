# SPDX-License-Identifier: MIT
#
# REA built from the source of an upstream release tag: the TypeScript
# compile, the runtime bundle and the generated skill, the steps
# upstream's `build` runs through turbo, run here directly. update.yml
# moves the version and both hashes.
#
# The package closes over the external tools REA can use that nixpkgs
# carries at a version REA accepts. Each optional tool is an argument
# that `.override { <attr> = null; }` removes; `rea-agents-minimal`
# removes all of them. Every location is set with `--set-default`, so
# a value the caller exports still takes precedence.
{
  lib,
  buildNpmPackage,
  callPackage,
  fetchFromGitHub,
  makeWrapper,
  nodejs_22,

  # Core: REA needs these whatever it analyzes.
  procps,
  util-linux,
  which,

  # Optional tools, each removable with `null`.
  android-tools,
  apktool,
  binutils,
  binwalk,
  chromium,
  gdb,
  ghidra,
  ilspycmd,
  jdk21,
  mitmproxy,
  rizin,
  unblob,
  wireshark-cli,
}:
let
  # `--set-default <variable> <path>` for a tool that is present.
  locate =
    package: variable: path:
    lib.optionals (package != null) [
      "--set-default"
      variable
      "${package}${path}"
    ];

  # REA runs `ps` before it launches any child on Linux, to check
  # process ownership, and `rea doctor` lists installs with `which`.
  # Both are looked up on `PATH`.
  corePath = [
    procps
    which
  ];

  # REA wraps tshark, sigrok, the firmware tools, wakaru and its EVM
  # worker in `prlimit`, at `/usr/bin/prlimit` unless these name
  # another. The EVM worker is REA's own Node process, so the minimal
  # package needs `prlimit` too.
  prlimitVariables = [
    "REA_TSHARK_PRLIMIT_COMMAND"
    "REA_SIGROK_PRLIMIT_COMMAND"
    "REA_FIRMWARE_PRLIMIT_COMMAND"
    "REA_JAVASCRIPT_PRLIMIT_COMMAND"
    "REA_EVM_PRLIMIT_COMMAND"
  ];

  wrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath corePath)
  ]
  ++ lib.concatMap (variable: locate util-linux variable "/bin/prlimit") prlimitVariables
  # REA starts Ghidra by running `java` itself with Ghidra's
  # LaunchSupport.jar, so the JDK that nixpkgs' Ghidra wrapper would
  # have supplied must be named here.
  ++ locate ghidra "GHIDRA_INSTALL_DIR" "/lib/ghidra"
  ++ lib.optionals (jdk21 != null) [
    "--set-default"
    "JAVA_HOME"
    jdk21.home
  ]
  ++ locate binutils "REA_OBJDUMP_COMMAND" "/bin/objdump"
  ++ locate rizin "REA_RIZIN_COMMAND" "/bin/rizin"
  ++ locate gdb "REA_GDB_COMMAND" "/bin/gdb"
  ++ locate wireshark-cli "REA_TSHARK_COMMAND" "/bin/tshark"
  ++ locate wireshark-cli "REA_CAPINFOS_COMMAND" "/bin/capinfos"
  ++ locate binwalk "REA_BINWALK_COMMAND" "/bin/binwalk"
  ++ locate unblob "REA_UNBLOB_COMMAND" "/bin/unblob"
  ++ locate android-tools "REA_ADB_PATH" "/bin/adb"
  ++ locate apktool "REA_APKTOOL_COMMAND" "/bin/apktool"
  # The capture bridge REA hands mitmdump requires mitmproxy 12.2.3.
  ++ locate mitmproxy "REA_MITMDUMP_COMMAND" "/bin/mitmdump"
  ++ locate chromium "REA_BROWSER_EXECUTABLE" "/bin/chromium"
  # Read only by `rea doctor`, which reports the version.
  ++ locate ilspycmd "REA_ILSPY_CMD_PATH" "/bin/ilspycmd";
in
buildNpmPackage (finalAttrs: {
  pname = "rea-agents";
  version = "6.7.0";

  src = fetchFromGitHub {
    owner = "morluto";
    repo = "rea";
    tag = "rea-agents-${finalAttrs.version}";
    hash = "sha256-GKgXQZdzsmr2bEffi+UaffY5TseJ7dSQvWwF1kuz2og=";
  };

  npmDepsHash = "sha256-BWMsF0ja+AyQg3w7BKVjzbI372HOKd2bFpFwbCAB5cA=";

  # Upstream's engines admit ^22.23.4, ^24.22.1 and >=26.12.1, and its
  # .npmrc makes npm refuse any other Node.
  nodejs = nodejs_22;

  # No lifecycle script runs. Upstream's `prepare` installs git hooks,
  # its `prepack` runs the turbo build again, and the optional `frida`
  # dependency downloads a prebuilt binding from the network.
  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    runHook preBuild
    npm run compile
    npm run artifacts:skills
    runHook postBuild
  '';

  # `frida` is installed without the binding its install script would
  # have downloaded, so it cannot load; it would ship only its test
  # executables. REA treats the dependency as optional.
  postInstall = ''
    rm -r $out/lib/node_modules/rea-agents/node_modules/frida
    for program in rea rea-agents; do
      wrapProgram $out/bin/$program ${lib.escapeShellArgs wrapperArgs}
    done
  '';

  passthru = {
    # The optional tools as given, `null` for one that was removed.
    # `rea-agents-minimal` sets every name here to `null`.
    tools = {
      inherit
        android-tools
        apktool
        binutils
        binwalk
        chromium
        gdb
        ghidra
        ilspycmd
        jdk21
        mitmproxy
        rizin
        unblob
        wireshark-cli
        ;
    };
    tests = {
      smoke = callPackage ./smoke.nix { rea-agents = finalAttrs.finalPackage; };
    }
    // lib.optionalAttrs (lib.any (tool: tool != null) (lib.attrValues finalAttrs.passthru.tools)) {
      tools = callPackage ./tools.nix { rea-agents = finalAttrs.finalPackage; };
    };
  };

  meta = {
    description = "MCP server and CLI for reverse engineering binaries, applications and runtime behavior";
    homepage = "https://github.com/morluto/rea";
    license = lib.licenses.mit;
    mainProgram = "rea";
    platforms = lib.platforms.linux;
  };
})
