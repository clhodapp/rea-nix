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
| `rea-agents` | the `rea` and `rea-agents` commands, built from upstream's newest stable release |
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

The package carries no analysis engine. REA finds Ghidra through
`GHIDRA_INSTALL_DIR` or a `ghidra` launcher on its `PATH`, and JADX on
its `PATH`, as upstream describes in its installation guide. The
wrapper adds procps to `PATH`, because REA checks process ownership
with `ps` before it launches a child process on Linux. The optional
Frida integration is left out.

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

`nix flake check` builds both packages and runs their smoke checks.
The check of `rea-agents` runs the CLI, an MCP `initialize` and
`tools/list` exchange over stdio (the catalog must not be empty, and
must have as many tools as the generated skill describes), the native
terminal addon, and a static analysis of a small JavaScript
application. The check of the skill reads its `SKILL.md` and every
reference it names. The skill package fails to build if it ever refers
to a store path.

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
