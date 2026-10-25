# rea-nix

Nix packaging of [REA](https://github.com/morluto/rea) ("Reverse
Engineer Anything"), an MCP server and command-line tool for reverse
engineering native binaries, JavaScript and Electron applications, .NET
assemblies and websites. Upstream distributes it as the npm package
`rea-agents` and installs it with `npx rea-agents setup`, which edits
the configuration of each agent in place. This flake builds the same
package from source instead, at a pinned release, and packages REA's
agent skill on its own, so that a Nix configuration installs it like
any other file.

| Package | What it is |
|---|---|
| `rea-agents` | the `rea` and `rea-agents` commands, built from upstream's newest stable release, with every tool REA can use that nixpkgs carries at a version REA accepts |
| `rea-agents-minimal` | the same commands with REA's core dependencies only |
| `reverse-engineer-anything` | REA's agent skill, the directory with its `SKILL.md` and `references/` |

## Use it

```sh
nix run github:clhodapp/rea-nix -- --help
```

As a flake input:

```nix
{
  inputs.rea-nix.url = "github:clhodapp/rea-nix";

  # a package:
  #   inputs.rea-nix.packages.${system}.rea-agents
  # or through the overlay, landing at pkgs.rea-nix.<package>:
  #   nixpkgs.overlays = [ inputs.rea-nix.overlays.default ];
}
```

## The tools REA uses

REA finds each external tool through an environment variable of its
own, and several of them through `PATH` as well. The wrapper of
`rea-agents` sets every one of those variables to a nixpkgs package,
with `--set-default`, so a value exported by the caller still takes
precedence.

| Tool | nixpkgs | How REA finds it |
|---|---|---|
| Ghidra 12.1, and the JDK it runs on | `ghidra`, `jdk21` | `GHIDRA_INSTALL_DIR`, `JAVA_HOME` |
| GNU objdump | `binutils` | `REA_OBJDUMP_COMMAND` |
| Rizin | `rizin` | `REA_RIZIN_COMMAND` |
| GDB | `gdb` | `REA_GDB_COMMAND` |
| TShark and capinfos | `wireshark-cli` | `REA_TSHARK_COMMAND`, `REA_CAPINFOS_COMMAND` |
| binwalk | `binwalk` | `REA_BINWALK_COMMAND` |
| unblob | `unblob` | `REA_UNBLOB_COMMAND` |
| adb | `android-tools` | `REA_ADB_PATH` |
| Apktool | `apktool` | `REA_APKTOOL_COMMAND` |
| mitmdump (REA's capture bridge requires mitmproxy 12.2.3) | `mitmproxy` | `REA_MITMDUMP_COMMAND` |
| Chromium | `chromium` | `REA_BROWSER_EXECUTABLE` |
| ILSpy (read only by `rea doctor`) | `ilspycmd` | `REA_ILSPY_CMD_PATH` |

Each of these is an argument of the package that an override removes:

```nix
pkgs.rea-nix.rea-agents.override { chromium = null; }
```

`rea-agents-minimal` removes all of them. Both packages keep REA's
core dependencies: procps, because REA checks process ownership with
`ps` before it launches any child process on Linux; `prlimit` from
util-linux, which REA wraps around tshark, the firmware tools and its
own EVM worker, and which it would otherwise look for at
`/usr/bin/prlimit`; and `which`, which `rea doctor` uses.

Some tools REA can use are not here. nixpkgs does not carry wakaru,
Kuna, pwndbg, the jadx-headless-mcp JAR that REA's JADX provider
loads, or the ghidra-nativeaot JAR. sigrok-cli, WABT and the Python
packages behind pwntools are in nixpkgs, but REA requires exact
versions they do not match. Hopper is unfree, and REA's Linux Hopper
path runs `/usr/bin/python3`, which NixOS does not provide. IDA is
proprietary and registered by the caller. The optional Frida
integration is left out, because its install script downloads a
prebuilt binding.

## The skill and the server

`reverse-engineer-anything` is the skill upstream's setup would copy
into an agent's skill directory, such as `~/.claude/skills` for Claude
Code. The build of `rea-agents` generates it for the tool catalog of
that version, and this package copies it out. It refers to no store
path, so installing it brings neither REA nor Node into the closure
of the configuration that installs it.

The skill drives REA's MCP tools, and this flake does not register the
server with any agent. REA opens untrusted files with the permissions
of whoever starts it. Its security policy says that its bridges "are
not a sandbox", and several of its analyses run the target. So the
consumer decides where the server runs and how an agent reaches it.
`rea-agents mcp` starts a server over stdio. A consumer that runs it
inside a virtual machine registers a client for it instead, for
example `socat STDIO VSOCK-CONNECT:<cid>:<port>`. The skill and the
server should come from the same `rea-nix` revision, since the skill
describes the tools of one version.

## Development

`nix flake check` builds the packages and runs their checks.
The check of `rea-agents` runs the CLI, an MCP `initialize` and
`tools/list` exchange over stdio (the catalog must not be empty, and
must have as many tools as the generated skill describes), the native
terminal addon, and a static analysis of a small JavaScript
application. It runs for `rea-agents-minimal` as well. A second check
of `rea-agents` uses the tools it closes over, each through the REA
command that needs it: `rea doctor` for Ghidra, a Ghidra decompile of
a small C program, objdump and Rizin on the same program, the TShark,
Apktool and adb client checks, and a binwalk scan. GDB, unblob,
mitmdump and Chromium are wired but not exercised. The check of the
skill reads its `SKILL.md` and every reference it names. The skill
package fails to build if it ever refers to a store path.

The checks earn their place. Upstream releases often, and a
successful build does not show that the server still starts, that the
skill is still generated, or that an analysis still runs.

`nix fmt` formats.

## Following upstream

A scheduled run (`.github/workflows/update.yml`, daily, or on demand
from the Actions tab) moves `rea-agents` to upstream's newest stable
release: the version, the source hash and the npm dependency hash. The
move is gated by both smoke checks. A move that fails is not pushed,
and the run shows as failed until whatever broke is fixed.

The same move by hand, from this directory:

```sh
nix run --inputs-from . 'nixpkgs#nix-update' -- --flake --version-regex 'rea-agents-(.*)' rea-agents
```

## Binary cache

What `main` builds is pushed to the `clhodapp` cachix cache, signed with
its key, so a consumer at the same pins substitutes the built package
instead of building it. That cache skips paths its upstreams already
hold, so using it means using them too:

| Substituter | Public key |
|---|---|
| `https://clhodapp.cachix.org` | `clhodapp.cachix.org-1:EW/0conxH0OQyo0o4ub/grdkFspholmQMSnQyj0vrZI=` |
| `https://nix-community.cachix.org` | `nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=` |
| `https://numtide.cachix.org` | `numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=` |

The flake's `nixConfig` declares all three, so a direct `nix build` or
`nix flake check` here uses them once accepted: answer Nix's prompt, or
pass `--accept-flake-config`. A flake that consumes this one as an
input must add them to its own `extra-substituters` and
`extra-trusted-public-keys`; Nix does not carry an input's settings
into the consumer.

## License

The packaging here is MIT, see [`LICENSE`](LICENSE). REA itself is MIT,
upstream.
