# SPDX-License-Identifier: MIT
#
# Exercises the built package over the interfaces consumers use: the
# CLI, the MCP server over stdio (the handshake and the tool catalog an
# agent reads), the generated skill, the native terminal addon, and a
# static JavaScript analysis, which launches workers behind REA's procps
# ownership check. A successful build alone shows none of these.
{
  coreutils,
  jq,
  runCommand,
  rea-agents,
}:
runCommand "rea-agents-smoke"
  {
    nativeBuildInputs = [
      coreutils
      jq
      rea-agents
    ];
  }
  ''
    export HOME=$TMPDIR/home
    mkdir -p "$HOME"
    package=${rea-agents}/lib/node_modules/rea-agents

    echo "CLI: rea --version"
    test "$(rea --version)" = ${rea-agents.version}

    echo "MCP: initialize, then tools/list, over stdio"
    {
      echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}'
      echo '{"jsonrpc":"2.0","method":"notifications/initialized"}'
      echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
      sleep 10
    } | timeout 60 rea-agents mcp > mcp.out 2> mcp.err || true
    cat mcp.err >&2
    jq -e 'select(.id == 1) | .result.serverInfo.name' mcp.out
    tools=$(jq -r 'select(.id == 2) | .result.tools | length' mcp.out)
    echo "the server lists $tools tools"
    test "$tools" -gt 0

    echo "Skill: ${rea-agents.skill}"
    test -s ${rea-agents.skill}/SKILL.md
    test -d ${rea-agents.skill}/references

    echo "Native addon: @lydell/node-pty"
    (cd "$package" && ${rea-agents.nodejs}/bin/node -e 'require("@lydell/node-pty")')

    echo "Static JavaScript analysis of a fixture application"
    mkdir -p app
    echo '{"name":"fixture","version":"1.0.0","main":"main.js"}' > app/package.json
    echo 'const { greet } = require("./greet"); console.log(greet("world"));' > app/main.js
    echo 'exports.greet = (name) => `hello ''${name}`;' > app/greet.js
    timeout 120 rea analyze-javascript-application "$PWD/app" --json > analysis.json
    jq -e '.' analysis.json > /dev/null
    grep -q greet analysis.json

    touch $out
  ''
