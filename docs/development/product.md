# rea-nix

## What it is

A Nix packaging of REA (github.com/morluto/rea), an MCP server and
CLI for reverse engineering binaries and applications, and of its
agent skill.

## Why it exists

Upstream installs REA with `npx rea-agents setup`, and keeps it current
with `rea update`. Both edit state in place: the setup writes an MCP
server entry into `~/.claude.json` and copies a skill into
`~/.claude/skills`, and the update replaces a global npm install. The
setup also refuses a symbolic link at the skill directory, which is how
home-manager installs every skill. This flake replaces both with a
package built from a pinned release and a skill package that a
home-manager configuration installs as a file. A scheduled workflow
moves the pin.

## Scope

- `rea-agents`: REA built from the source of upstream's newest stable
  release tag (`rea-agents-<version>`), with Node 22 (upstream's
  engines admit ^22.23.4, ^24.22.1 and >=26.12.1). It closes over every
  external tool REA can use that nixpkgs carries at a version REA
  accepts, each named by REA's own environment variable and removable
  with `.override { <attr> = null; }`.
- `rea-agents-minimal`: the same package with every optional tool
  removed, keeping REA's core dependencies (procps, util-linux for
  `prlimit`, `which`).
- `reverse-engineer-anything`: the skill REA's build generates, copied
  out of `rea-agents-minimal` with no store references, so the machine
  that runs the agent does not carry the server.

Not yet provided, each a packaging task of its own: the tools nixpkgs
lacks (wakaru, Kuna, pwndbg, the jadx-headless-mcp 0.7.1 JAR, the
ghidra-nativeaot JAR), and the ones REA pins to versions nixpkgs does
not have (sigrok-cli 0.7.2, WABT 1.0.42, pyelftools 0.33 and unicorn
2.1.2 for pwntools).

Out of scope:

- Hopper, which is unfree and whose Linux path in REA runs
  `/usr/bin/python3`, `/usr/bin/unshare`, `/usr/bin/Xvfb` and
  `/usr/bin/xauth` with no override; and IDA, which is proprietary.
- Where REA runs, and the MCP server entry an agent uses to reach it.
  REA runs with the permissions of whoever starts it, and some
  analyses run the target. In the workspace, the server is meant to
  run inside a microvm.nix guest of chris-desktop-2, reached over
  vsock. The server entry is generated where the vsock address is
  decided, on the side of the host or the workbench.
- Frida, which upstream installs as an optional dependency whose
  install script downloads a prebuilt binding.

## Consumers

- `ch-ai-workbench` or `ch-personal-machines` (not yet wired): the
  skill, and an MCP server entry for the vsock client.
- The rea microvm guest (not yet built): `rea-agents`.
