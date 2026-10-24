# SPDX-License-Identifier: MIT
#
# A Claude Code skills-dir plugin for REA: the skill REA's build
# generates, and the MCP server entry that gives an agent REA's tools.
# Claude Code loads it in place from a directory under
# `~/.claude/skills`, with no marketplace and no install step.
#
# The plugin declares no MCP server until its consumer names one with
# `.override { mcpServer = { command; args; env; }; }`. REA runs its
# analysis with the permissions of whoever starts it, so where it runs
# is the consumer's decision: the command is typically a client for a
# server inside a virtual machine, and `${rea-agents}/bin/rea-agents
# mcp` starts one on the host itself.
{
  callPackage,
  jq,
  lib,
  rea-agents,
  runCommand,
  mcpServer ? null,
}:
let
  manifest = {
    name = "rea";
    inherit (rea-agents) version;
    description = "REA reverse-engineering tools and their workflow skill for Claude Code";
  }
  // lib.optionalAttrs (mcpServer != null) {
    mcpServers.rea = {
      inherit (mcpServer) command;
      args = mcpServer.args or [ ];
      env = mcpServer.env or { };
    };
  };
in
runCommand "rea-claude-code-plugin-${rea-agents.version}"
  {
    nativeBuildInputs = [ jq ];
    manifest = builtins.toJSON manifest;
    passAsFile = [ "manifest" ];
    passthru.tests.smoke = callPackage ./smoke.nix { inherit rea-agents; };
    meta = {
      description = "Claude Code skills-dir plugin for REA";
      license = lib.licenses.mit;
    };
  }
  ''
    mkdir -p "$out/.claude-plugin" "$out/skills"
    jq . "$manifestPath" > "$out/.claude-plugin/plugin.json"
    cp -r ${rea-agents.skill} "$out/skills/reverse-engineer-anything"
  ''
