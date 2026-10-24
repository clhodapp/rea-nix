# Technology Stack

- **Nix** for package definitions and checks
- **caisson** for `mkLib`, the package overlay registry, and the flake
  outputs ([github:nix-caisson/caisson](https://github.com/nix-caisson/caisson))
- **nixpkgs unstable** (`nixos-unstable`): `buildNpmPackage`,
  `nodejs_22`, procps
- **REA**, fetched with `fetchFromGitHub` at a release tag, without
  its git submodules. The submodules hold third-party tools
  (binwalk, unblob, wakaru, jadx-headless-mcp, ghidra-nativeaot) that
  the npm package does not ship.
- **The build** runs upstream's `compile` and `artifacts:skills` npm
  scripts directly: `tsc` (TypeScript 7), the rolldown runtime bundle,
  and the skill generator. Upstream's `build` script runs the same
  steps through turbo. Every npm call passes `--ignore-scripts`.
- **nix-update** moves the version, the source hash and
  `npmDepsHash` (`.github/workflows/update.yml`).
- **GitHub Actions** for the cached check pipeline and the update
  workflow, copied from merman-nix.
