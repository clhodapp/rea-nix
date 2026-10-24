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
- `smoke-reverse-engineer-anything`
  (`pkgs/reverse-engineer-anything/smoke.nix`): `SKILL.md` names the
  skill in its front matter, and every `references/*.md` it names
  exists. The package's `allowedReferences = [ ]` makes its own build
  fail if the skill refers to a store path.
- `treefmt`.

The update workflow builds both smoke checks by name before it
commits a bump.

Gotchas: the MCP exchange writes the requests and then keeps stdin
open for ten seconds, because the server stops reading when stdin
closes and may not have answered yet. The analysis in the smoke check
needs no engine; the Ghidra and JADX paths are exercised only where an
engine is installed, which is not in this repository.
