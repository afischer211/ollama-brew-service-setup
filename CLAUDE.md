# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project does

Bridges the gap between Homebrew's Ollama service and `.env`-based configuration. Homebrew services don't natively support `.env` files, so `update-ollama-brew-plist-env-vars.sh` parses `.env` and uses macOS `PlistBuddy` to inject each key/value into the `EnvironmentVariables` dict of `~/Library/LaunchAgents/homebrew.mxcl.ollama.plist`.

## Key scripts

| Script | What it does |
|---|---|
| `scripts/update-ollama-brew-plist-env-vars.sh` | Core script: copies plist template if absent, auto-creates `.env` from `.env.example` if absent, then syncs all non-empty, non-commented `.env` vars into the installed plist via PlistBuddy |
| `scripts/start-ollama-brew-service.sh` | Runs the update script, then calls `brew services --file $PLIST start ollama` |
| `scripts/stop-ollama-brew-service.sh` | Calls `brew services stop ollama` |
| `scripts/log-ollama-brew-service.sh` | Tails `/opt/homebrew/var/log/ollama.log` |

## Data flow

```
.env (project root)
  → update-ollama-brew-plist-env-vars.sh
    → ~/Library/LaunchAgents/homebrew.mxcl.ollama.plist  (PlistBuddy writes EnvironmentVariables)
      → launchd / brew services
```

`resources/homebrew.mxcl.ollama.plist` is the **template** copied on first run. Edits to environment variables must always go through the update script (or directly via PlistBuddy), never by hand-editing the installed plist.

## Platform constraints

- macOS only — depends on `launchd`, `PlistBuddy`, and Homebrew
- Ollama must be installed via `brew install ollama` (binary expected at `/opt/homebrew/opt/ollama/bin/ollama`)
- No build system, no test suite, no package manager

## `.env` parsing rules (in update script)

- Lines starting with `#` or empty lines are skipped
- Keys with empty values (after stripping optional surrounding quotes) are skipped
- Only valid env var names (`[A-Za-z_][A-Za-z0-9_]*`) are accepted; others emit a warning and are skipped
- Existing plist keys are deleted then re-added (PlistBuddy has no update command)
