# SPDX-License-Identifier: MIT
#
# REA's agent skill, `reverse-engineer-anything`: the directory
# upstream's setup would copy into an agent's skill directory, with its
# `SKILL.md` and `references/`. The build of rea-agents generates it
# for that version's tool catalog, so the skill and the server it
# describes come from the same pin.
#
# The skill is copied out of rea-agents and refers to no store path,
# so installing it does not bring the server and its Node runtime into
# the closure of the configuration that installs it. A skill and the
# MCP server it drives can then live on different machines: the skill
# beside the agent, the server wherever the consumer runs REA.
{
  callPackage,
  lib,
  rea-agents,
  runCommand,
}:
runCommand "reverse-engineer-anything-${rea-agents.version}"
  {
    inherit (rea-agents) version;
    allowedReferences = [ ];
    passthru.tests.smoke = callPackage ./smoke.nix { };
    meta = {
      description = "REA's agent skill for reverse engineering with its MCP tools";
      homepage = "https://github.com/morluto/rea";
      license = lib.licenses.mit;
    };
  }
  ''
    cp -r ${rea-agents}/lib/node_modules/rea-agents/skills/reverse-engineer-anything $out
  ''
