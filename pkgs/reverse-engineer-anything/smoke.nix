# SPDX-License-Identifier: MIT
#
# Checks the skill as an agent's skill directory reads it: a `SKILL.md`
# whose front matter names the skill, and the `references/` it points
# into. The package's own `allowedReferences` already fails the build
# of a skill that refers to a store path.
{
  reverse-engineer-anything,
  runCommand,
}:
runCommand "reverse-engineer-anything-smoke" { } ''
  skill=${reverse-engineer-anything}
  echo "Skill $skill"
  test -s "$skill/SKILL.md"
  grep -q '^name: reverse-engineer-anything$' "$skill/SKILL.md"
  test -d "$skill/references"
  for reference in $(grep -o 'references/[A-Za-z0-9._-]*\.md' "$skill/SKILL.md" | sort -u); do
    echo "SKILL.md names $reference"
    test -s "$skill/$reference"
  done
  touch $out
''
