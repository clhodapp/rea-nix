# SPDX-License-Identifier: MIT
#
# pwndbg as its own flake publishes it, at the release REA's
# recorded-crash bridge accepts (it requires pwndbg's version to be
# exactly 2026.09.15). The flake builds pwndbg's Python environment
# from upstream's lock; REA points at that environment, at the
# gdbinit.py it installs, and at the GDB it carries, through
# `meta.pwndbgVenv`.
{
  pwndbgFlake,
  stdenv,
}:
pwndbgFlake.packages.${stdenv.hostPlatform.system}.pwndbg
