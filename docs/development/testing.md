# Testing

From the repository root:

```zsh
nix flake check
```

Checks (x86_64-linux, checks partition):

- `smoke-rea-agents` (`pkgs/rea-agents/smoke.nix`): `rea --version`
  matches the package version; an MCP `initialize`, then `tools/list`,
  over stdio returns the server name `rea` and a non-empty tool
  catalog; the generated skill has its `SKILL.md` and `references/`,
  and the `tool_count` in its front matter equals the number of tools
  the server lists;
  `@lydell/node-pty`, the one native addon, loads; and
  `rea analyze-javascript-application` reads a three-file fixture
  application and reports its module graph. The analysis launches
  workers, which REA starts only after checking process ownership with
  procps `ps`.
- `smoke-rea-agents-minimal`: the same smoke check against the package
  without its optional tools.
- `tools-rea-agents` (`pkgs/rea-agents/tools.nix`): each closed-over
  tool through the REA command that uses it, against a small C program
  the check compiles. `rea doctor --provider ghidra` must report
  healthy with every check passing; `rea decompile --provider ghidra`
  must decompile `add_numbers`, which launches Ghidra headless on the
  JDK the wrapper names; `rea doctor` must report ILSpy;
  `inspect-with-objdump ... symbols` and `execute-rizin-command ... i`
  read the program; `inspect-pcap-client`, `inspect-apktool-client` and
  `inspect-adb-client` must accept their tools; and
  `inspect-firmware-regions` must find a gzip stream that binwalk
  scans under `prlimit`. A tool removed with an override is skipped.
  GDB, unblob, mitmdump and Chromium are wired but not exercised: each
  needs a live target, an extraction or a browser launch.
- `smoke-reverse-engineer-anything`
  (`pkgs/reverse-engineer-anything/smoke.nix`): `SKILL.md` names the
  skill in its front matter, and every `references/*.md` it names
  exists. The package's `allowedReferences = [ ]` makes its own build
  fail if the skill refers to a store path.
- `treefmt`.

The update workflow builds every check above by name before it
commits a bump. The tools check fetches Ghidra, Chromium and the other
tools: the closure of `rea-agents` is about 4.2 GiB, against 362 MiB
for `rea-agents-minimal`, nearly all of it served by cache.nixos.org.

Gotchas: the MCP exchange writes the requests and then keeps stdin
open for ten seconds, because the server stops reading when stdin
closes and may not have answered yet. The analysis in the smoke check
needs no engine; the Ghidra and JADX paths are exercised only where an
engine is installed, which is not in this repository.
