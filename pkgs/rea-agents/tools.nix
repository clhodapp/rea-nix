# SPDX-License-Identifier: MIT
#
# Exercises the tools the package closes over, each through the REA
# command that uses it, so the test fails when REA cannot find a tool
# where the wrapper says it is. A tool the package was built without
# (`.override { <attr> = null; }`) is skipped.
#
# The fixture is a small C program compiled here, so Ghidra, Kuna,
# objdump, rizin and pwntools read a real ELF executable. It runs only
# under GDB, stopped at a breakpoint, to write the core file the
# recorded-crash check reads.
{
  coreutils,
  gdb,
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

    ${with' [ "kuna" ] ''
      run kuna decompile "$fixture" add_numbers --provider kuna
      grep -q add_numbers kuna.json
    ''}

    ${with' [ "wakaru" ] ''
      echo 'var a=function(n){return n+1};module.exports={inc:a};' > "$PWD/bundle.js"
      run wakaru recover-javascript-sources "$PWD/bundle.js" "$PWD/recovered"
      test -d recovered
    ''}

    ${with' [ "rea-sigrok-cli" ] ''
      run sigrok inspect-signal-decoders --query uart
      grep -q -i uart sigrok.json
    ''}

    ${with' [ "rea-wabt" ] ''
      printf '\0asm\1\0\0\0' > empty.wasm
      run wasm inspect-wasm-artifact "$PWD/empty.wasm"
    ''}

    ${with' [ "rea-pwntools-python" ] ''
      run layout inspect-binary-layout "$fixture"
      jq -e '.provider.id == "pwntools-elf"' layout.json
    ''}

    ${with' [ "rea-pwntools-python" "pwndbg" ] ''
      ${gdb}/bin/gdb -nx -batch -ex 'break add_numbers' -ex run \
        -ex 'generate-core-file fixture.core' "$fixture"
      run crash inspect-recorded-crash "$PWD/fixture.core" --debugger-context
      jq -e '.provider.id == "pwntools-elf" and .normalized_result.debugger.status == "available"' crash.json
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
