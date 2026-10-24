# SPDX-License-Identifier: MIT
#
# Checks the plugin in the two forms a consumer gets. Without
# `mcpServer` the manifest declares no server. With one, the manifest
# names it, and the command it names answers an MCP handshake; the test
# names a server on the host, which the sandbox of this build allows.
# Both forms carry the skill where Claude Code looks for it.
{
  callPackage,
  coreutils,
  jq,
  rea-agents,
  runCommand,
}:
let
  bare = callPackage ./. { inherit rea-agents; };
  withServer = callPackage ./. {
    inherit rea-agents;
    mcpServer = {
      command = "${rea-agents}/bin/rea-agents";
      args = [ "mcp" ];
      env.REA_MCP_INPUT_SCHEMA_PROFILE = "compact";
    };
  };
in
runCommand "rea-claude-code-plugin-smoke"
  {
    nativeBuildInputs = [
      coreutils
      jq
    ];
  }
  ''
    export HOME=$TMPDIR/home
    mkdir -p "$HOME"

    for plugin in ${bare} ${withServer}; do
      echo "Plugin $plugin"
      jq -e '.name == "rea" and .version == "${rea-agents.version}"' "$plugin/.claude-plugin/plugin.json"
      test -s "$plugin/skills/reverse-engineer-anything/SKILL.md"
    done

    echo "Without mcpServer: no server"
    jq -e 'has("mcpServers") | not' ${bare}/.claude-plugin/plugin.json

    echo "With mcpServer: the named server answers"
    manifest=${withServer}/.claude-plugin/plugin.json
    jq -e '.mcpServers.rea.env.REA_MCP_INPUT_SCHEMA_PROFILE == "compact"' "$manifest"
    command=$(jq -r '.mcpServers.rea.command' "$manifest")
    mapfile -t args < <(jq -r '.mcpServers.rea.args[]' "$manifest")
    {
      echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}'
      sleep 10
    } | timeout 60 "$command" "''${args[@]}" > mcp.out || true
    jq -e 'select(.id == 1) | .result.serverInfo.name == "rea"' mcp.out

    touch $out
  ''
