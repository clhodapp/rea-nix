# Commands

From the repository root.

Build the package and run it:

```zsh
nix build '.#rea-agents'
nix run '.#rea-agents' -- --version
```

Run one smoke check with its log:

```zsh
nix build --no-link -L '.#checks.x86_64-linux.smoke-rea-agents'
nix build --no-link -L '.#checks.x86_64-linux.smoke-reverse-engineer-anything'
```

Move `rea-agents` to upstream's newest stable release, as the update
workflow does:

```zsh
nix run --inputs-from . 'nixpkgs#nix-update' -- --flake --version-regex 'rea-agents-(.*)' rea-agents
```

Format:

```zsh
nix fmt
```
