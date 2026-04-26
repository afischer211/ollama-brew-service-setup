#!/bin/bash

# Resolve symlinks so the script works correctly when called via a softlink
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

OLLAMA_HOME="$HOME/.ollama"

SCRIPTS_TO_LINK=(
    "log-ollama-brew-service.sh"
    "start-ollama-brew-service.sh"
    "stop-ollama-brew-service.sh"
    "update-ollama-brew-plist-env-vars.sh"
)

# --- Check Ollama availability ---
echo "Checking for Ollama installation..."
if ! OLLAMA_VERSION=$(ollama -v 2>&1); then
    echo "Error: Ollama not found. Please install it first:"
    echo "  brew install ollama"
    exit 1
fi
echo "Found: $OLLAMA_VERSION"
echo ""

# --- Copy resources and .env.example (skipped if already present) ---
RESOURCES_EXISTS=0
ENV_EXAMPLE_EXISTS=0
[ -e "$OLLAMA_HOME/resources" ]    && RESOURCES_EXISTS=1
[ -f "$OLLAMA_HOME/.env.example" ] && ENV_EXAMPLE_EXISTS=1

if [ "$RESOURCES_EXISTS" -eq 1 ] && [ "$ENV_EXAMPLE_EXISTS" -eq 1 ]; then
    echo "Config files already present in $OLLAMA_HOME — skipping copy."
    echo ""
else
    # Ensure $OLLAMA_HOME exists
    if [ ! -d "$OLLAMA_HOME" ]; then
        echo "Creating $OLLAMA_HOME..."
        mkdir -p "$OLLAMA_HOME"
    fi

    if [ "$RESOURCES_EXISTS" -eq 0 ]; then
        echo "Copying resources/ to $OLLAMA_HOME/resources/ ..."
        if ! cp -r "$PROJECT_ROOT/resources" "$OLLAMA_HOME/resources"; then
            echo "Error: Failed to copy resources folder."
            exit 1
        fi
        echo "Done."
    else
        echo "Skipping resources/ — already exists."
    fi

    if [ "$ENV_EXAMPLE_EXISTS" -eq 0 ]; then
        echo "Copying .env.example to $OLLAMA_HOME/.env.example ..."
        if ! cp "$PROJECT_ROOT/.env.example" "$OLLAMA_HOME/.env.example"; then
            echo "Error: Failed to copy .env.example."
            exit 1
        fi
        echo "Done."
    else
        echo "Skipping .env.example — already exists."
    fi

    echo ""
fi

# --- Create symlinks (optional) ---
echo "Enter a target folder to create symlinks for the service scripts,"
echo "or press Enter to skip this step."
read -r -p "Target folder: " LINK_TARGET

if [ -z "$LINK_TARGET" ]; then
    echo "Skipping symlink creation."
else
    # Expand ~ manually in case the user typed it
    LINK_TARGET="${LINK_TARGET/#\~/$HOME}"

    if [ ! -d "$LINK_TARGET" ]; then
        read -r -p "$LINK_TARGET does not exist. Create it? [y/N] " CREATE_DIR
        if [[ "$CREATE_DIR" =~ ^[Yy]$ ]]; then
            if ! mkdir -p "$LINK_TARGET"; then
                echo "Error: Failed to create $LINK_TARGET."
                exit 1
            fi
            echo "Created $LINK_TARGET."
        else
            echo "Skipping symlink creation — target folder does not exist."
            LINK_TARGET=""
        fi
    fi

    if [ -n "$LINK_TARGET" ]; then
        echo ""
        echo "Creating symlinks in $LINK_TARGET ..."
        for script in "${SCRIPTS_TO_LINK[@]}"; do
            SOURCE="$SCRIPT_DIR/$script"
            TARGET="$LINK_TARGET/$script"
            if [ ! -f "$SOURCE" ]; then
                echo "  Warning: $SOURCE not found, skipped."
                continue
            fi
            ln -sf "$SOURCE" "$TARGET"
            echo "  Linked: $TARGET -> $SOURCE"
        done
        echo "Done."
    fi
fi

echo ""
echo "Next steps:"
if [ ! -f "$OLLAMA_HOME/.env" ]; then
echo "  1. Copy and edit the env file:  cp $OLLAMA_HOME/.env.example $OLLAMA_HOME/.env"
echo "  2. Apply config and start:      $SCRIPT_DIR/start-ollama-brew-service.sh"
else
echo "  1. Apply config and start:      $SCRIPT_DIR/start-ollama-brew-service.sh"
fi
