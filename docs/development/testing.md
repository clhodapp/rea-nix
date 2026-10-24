# Testing

From the repository root:

```zsh
nix flake check
```

Checks (x86_64-linux, checks partition):

- `smoke-rea-agents` (`pkgs/rea-agents/smoke.nix`): `rea --version`
  matches the package version; an MCP `initialize`, then `tools/list`,
  over stdio returns the server name `rea` and a non-empty tool
  catalog; the generated skill has its `SKILL.md` and `references/`;
  `@lydell/node-pty`, the one native addon, loads; and
  `rea analyze-javascript-application` reads a three-file fixture
  application and reports its module graph. The analysis launches
  workers, which REA starts only after checking process ownership with
  procps `ps`.
- `smoke-claude-code-plugin` (`pkgs/claude-code-plugin/smoke.nix`):
  the plugin without `mcpServer` declares no server; with one, the
  manifest names it with its environment, and the command it names
  answers an MCP `initialize`. Both forms carry the skill.
- `treefmt`.

The update workflow builds both smoke checks by name before it
commits a bump.

Gotchas: the MCP exchange writes the requests and then keeps stdin
open for ten seconds, because the server stops reading when stdin
closes and may not have answered yet. The analysis in the smoke check
needs no engine; the Ghidra and JADX paths are exercised only where an
engine is installed, which is not in this repository.
