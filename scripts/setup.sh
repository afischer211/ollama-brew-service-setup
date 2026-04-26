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

# --- Check Ollama availability ---
echo "Checking for Ollama installation..."
if ! OLLAMA_VERSION=$(ollama -v 2>&1); then
    echo "Error: Ollama not found. Please install it first:"
    echo "  brew install ollama"
    exit 1
fi
echo "Found: $OLLAMA_VERSION"
echo ""

# --- Check target files do not already exist ---
CONFLICT=0
if [ -e "$OLLAMA_HOME/resources" ]; then
    echo "Already exists: $OLLAMA_HOME/resources"
    CONFLICT=1
fi
if [ -f "$OLLAMA_HOME/.env.example" ]; then
    echo "Already exists: $OLLAMA_HOME/.env.example"
    CONFLICT=1
fi
if [ "$CONFLICT" -eq 1 ]; then
    echo ""
    echo "Setup aborted: target files already exist inside $OLLAMA_HOME."
    echo "Remove them manually before running setup again."
    exit 1
fi

# --- Ensure $OLLAMA_HOME exists ---
if [ ! -d "$OLLAMA_HOME" ]; then
    echo "Creating $OLLAMA_HOME..."
    mkdir -p "$OLLAMA_HOME"
fi

# --- Copy resources folder ---
echo "Copying resources/ to $OLLAMA_HOME/resources/ ..."
if ! cp -r "$PROJECT_ROOT/resources" "$OLLAMA_HOME/resources"; then
    echo "Error: Failed to copy resources folder."
    exit 1
fi
echo "Done."

# --- Copy .env.example ---
echo "Copying .env.example to $OLLAMA_HOME/.env.example ..."
if ! cp "$PROJECT_ROOT/.env.example" "$OLLAMA_HOME/.env.example"; then
    echo "Error: Failed to copy .env.example."
    exit 1
fi
echo "Done."

echo ""
echo "Setup complete. Next steps:"
echo "  1. Copy and edit the env file:  cp $OLLAMA_HOME/.env.example $OLLAMA_HOME/.env"
echo "  2. Apply config and start:      $SCRIPT_DIR/start-ollama-brew-service.sh"
