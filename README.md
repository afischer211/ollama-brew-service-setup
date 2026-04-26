# Ollama Homebrew Service Setup

This repository provides a set of scripts to simplify the setup and management of
[Ollama](https://ollama.com/) as a background service on macOS using Homebrew.

It allows you to easily configure Ollama with environment variables
(e.g., `OLLAMA_HOST`, `OLLAMA_MODELS`) by using a `.env` file, which is not
natively supported by Homebrew services.

## Features

- **Guided Setup**: A single setup script initialises everything and optionally
  creates symlinks so the service scripts are available system-wide.
- **Automated Plist Configuration**: Automatically generates the required
  `homebrew.mxcl.ollama.plist` file in `~/Library/LaunchAgents`.
- **`$HOME/.ollama`-first Config**: The scripts look for `.env` and the plist
  template in `~/.ollama` first, falling back to the project directory.
- **Simple Service Control**: Convenient scripts to start, stop, and view logs,
  with process and version checks built in.
- **Symlink-safe**: All scripts resolve symlinks at runtime, so they work
  correctly when called from a different directory via a softlink.

## Prerequisites

- **macOS**
- **Homebrew**: If not installed, see [brew.sh](https://brew.sh/).
- **Ollama** installed via Homebrew:

  ```bash
  brew install ollama
  ```

## Installation

### 1. Clone this repository

```bash
git clone https://github.com/afischer211/ollama-brew-service-setup.git
cd ollama-brew-service-setup
```

### 2. Run the setup script

```bash
./scripts/setup.sh
```

The setup script will:

1. Verify that Ollama is installed.
2. Copy the `resources/` folder (containing the plist template) and
   `.env.example` into `~/.ollama/`. These are skipped individually if they
   already exist, so re-running setup is safe.
3. Ask for an optional target folder to create symlinks for the service scripts.
   Press Enter to skip this step.

### 3. Configure environment variables

The primary location for your `.env` file is `~/.ollama/.env`. Copy the
example file and edit it to your needs:

```bash
cp ~/.ollama/.env.example ~/.ollama/.env
```

Example settings:

```dotenv
# Make Ollama accessible on your local network
OLLAMA_HOST=0.0.0.0

# Store models on an external drive
OLLAMA_MODELS=/Volumes/External/ollama_models
```

After editing `.env`, run the start script (or the update script alone) to
apply the changes to the service.

## Service Management

### Start

```bash
./scripts/start-ollama-brew-service.sh
```

Applies the current `.env` to the plist, starts the service, waits for the
Ollama process to appear, and checks `ollama -v` for client/server version
mismatches.

### Stop

```bash
./scripts/stop-ollama-brew-service.sh
```

Stops the service and waits for the Ollama process to exit, reporting whether
it stopped cleanly within 10 seconds.

### View logs

```bash
./scripts/log-ollama-brew-service.sh
```

Tails the Ollama log at `/opt/homebrew/var/log/ollama.log`.

### Check service status

```bash
brew services list
```

`ollama` should appear with a `started` status.

### Apply config changes without restarting

```bash
./scripts/update-ollama-brew-plist-env-vars.sh
```

Reads `~/.ollama/.env` (or `<project>/.env` as fallback) and writes all
variables into the `EnvironmentVariables` section of the installed plist.

## Using symlinks

If you created symlinks during setup (or re-run `./scripts/setup.sh` to
create them later), you can call the scripts from anywhere:

```bash
start-ollama-brew-service.sh
stop-ollama-brew-service.sh
log-ollama-brew-service.sh
update-ollama-brew-plist-env-vars.sh
```

All scripts resolve their own location at runtime, so symlinks work correctly
regardless of the calling directory.

## Config file lookup order

| File | Primary location | Fallback |
|---|---|---|
| `.env` | `~/.ollama/.env` | `<project>/.env` |
| `.env.example` | `~/.ollama/.env.example` | `<project>/.env.example` |
| plist template | `~/.ollama/resources/homebrew.mxcl.ollama.plist` | `<project>/resources/homebrew.mxcl.ollama.plist` |

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
