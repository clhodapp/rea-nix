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
  engines admit ^22.23.4, ^24.22.1 and >=26.12.1).
- `reverse-engineer-anything`: the skill REA's build generates, copied
  out of `rea-agents` with no store references, so the machine that
  runs the agent does not carry the server.

Out of scope:

- The analysis engines. Ghidra and JADX come from nixpkgs, put on the
  `PATH` of the environment REA runs in, by the configuration that
  runs it.
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
- The rea microvm guest (not yet built): `rea-agents`, with Ghidra,
  JADX and Xvfb beside it.
