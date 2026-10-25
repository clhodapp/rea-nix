# SPDX-License-Identifier: MIT
#
# Exercises the tools the package closes over, each through the REA
# command that uses it, so the test fails when REA cannot find a tool
# where the wrapper says it is. A tool the package was built without
# (`.override { <attr> = null; }`) is skipped.
#
# The fixture is a small C program compiled here, so Ghidra, objdump
# and rizin read a real ELF executable; it is never run.
{
  coreutils,
  gnugrep,
  gzip,
  jq,
  lib,
  runCommandCC,
  rea-agents,
}:
let
  inherit (rea-agents) tools;
  with' = names: script: lib.optionalString (lib.all (name: tools.${name} != null) names) script;
in
runCommandCC "rea-agents-tools"
  {
    nativeBuildInputs = [
      coreutils
      gnugrep
      gzip
      jq
      rea-agents
    ];
  }
  ''
    export HOME=$TMPDIR/home
    mkdir -p "$HOME"

    # Runs one REA command, keeps its JSON output in $1.json, and fails
    # the test with the command's error output when it fails.
    run() {
      local name=$1
      shift
      echo "== $name: rea $*"
      if ! timeout 600 rea "$@" --format json > "$name.json" 2> "$name.err"; then
        cat "$name.err" >&2
        head -c 4000 "$name.json" >&2
        echo "rea $* failed" >&2
        exit 1
      fi
      jq -e . "$name.json" > /dev/null
    }

    cat > fixture.c <<'EOF'
    int add_numbers(int a, int b) { return a + b; }
    int main(void) { return add_numbers(2, 3); }
    EOF
    $CC -O0 -o fixture fixture.c
    fixture=$PWD/fixture

    ${with' [ "ghidra" "jdk21" ] ''
      run doctor doctor --provider ghidra
      jq -e '.healthy == true and all(.scope_checks[]; .ok)' doctor.json
      run decompile decompile "$fixture" add_numbers --provider ghidra
      head -c 2000 decompile.json
      echo
      grep -q add_numbers decompile.json
    ''}

    ${with' [ "ilspycmd" ] ''
      run doctor-ilspy doctor --provider ghidra
      jq -e '.informational_checks[] | select(.name == "ilspycmd") | .ok' doctor-ilspy.json
    ''}

    ${with' [ "binutils" ] ''
      run objdump inspect-with-objdump "$fixture" symbols
      grep -q add_numbers objdump.json
    ''}

    ${with' [ "rizin" ] ''
      run rizin execute-rizin-command "$fixture" i
      grep -q -i elf rizin.json
    ''}

    ${with' [ "wireshark-cli" ] ''
      run pcap-client inspect-pcap-client
    ''}

    ${with' [ "apktool" ] ''
      run apktool-client inspect-apktool-client
    ''}

    ${with' [ "android-tools" ] ''
      run adb-client inspect-adb-client
    ''}

    ${with' [ "binwalk" ] ''
      head -c 4096 /dev/zero > firmware.bin
      echo 'a gzip stream inside a firmware image' | gzip >> firmware.bin
      head -c 4096 /dev/zero >> firmware.bin
      run firmware inspect-firmware-regions "$PWD/firmware.bin"
      grep -q -i gzip firmware.json
    ''}

    touch $out
  ''
