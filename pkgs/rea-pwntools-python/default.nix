# SPDX-License-Identifier: MIT
#
# The Python REA runs its pwntools bridges with (`REA_PWNTOOLS_PYTHON`),
# for ELF layout and recorded-crash analysis. The bridges read the
# installed versions with `importlib.metadata` and accept exactly
# pwntools 4.15.0, pyelftools 0.33 and unicorn 2.1.2. nixpkgs has the
# pwntools release, an older pyelftools and a newer unicorn, so this
# environment overrides the two, scoped to this Python only; a global
# override of unicorn would rebuild everything else that uses it.
#
# The unicorn binding takes its version and source from the C library,
# so both move to 2.1.2. At 2.1.2 the binding reads its version with
# versioningit, which finds none in a source tree without git
# metadata; the default it falls back to is set here.
{
  fetchFromGitHub,
  python3,
  unicorn,
}:
let
  unicorn-2-1-2 = unicorn.overrideAttrs (
    finalAttrs: previous: {
      version = "2.1.2";
      src = previous.src.override {
        tag = finalAttrs.version;
        hash = "sha256-qA84xBztyWmt/rUExhhZMkQzvDPx0UE9MAIPG/Su3iE=";
      };
    }
  );

  python = python3.override {
    self = python;
    packageOverrides = final: previous: {
      pyelftools = previous.pyelftools.overridePythonAttrs (_: rec {
        version = "0.33";
        src = fetchFromGitHub {
          owner = "eliben";
          repo = "pyelftools";
          tag = "v${version}";
          hash = "sha256-NqF5A6PRl4uncwNS9j44fIV7ovlljiucvV2Msv0LK/w=";
        };
      });
      unicorn = (previous.unicorn.override { unicorn = unicorn-2-1-2; }).overridePythonAttrs (old: {
        build-system = old.build-system ++ [ final.versioningit ];
        # The `[tool.versioningit]` table ends pyproject.toml, so the
        # appended key lands in it.
        postPatch = (old.postPatch or "") + ''
          echo 'default-version = "${unicorn-2-1-2.version}"' >> pyproject.toml
        '';
      });
    };
  };
in
python.withPackages (packages: [ packages.pwntools ])
