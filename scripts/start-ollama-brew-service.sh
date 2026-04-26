#!/bin/bash

echo "Update plist and start Ollama service with brew."

# Resolve symlinks so the update script is found even when called via a softlink
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"

# Call the plist update script with absolute path
"$SCRIPT_DIR/update-ollama-brew-plist-env-vars.sh"
UPDATE_STATUS=$?

if [ $UPDATE_STATUS -ne 0 ]; then
    echo "Plist update failed. Ollama service will not be started."
    exit 1
fi

PLIST="$HOME/Library/LaunchAgents/homebrew.mxcl.ollama.plist"

if [ ! -f "$PLIST" ]; then
    echo "Error: $PLIST not found."
    exit 1
fi

brew services --file "$PLIST" start ollama

# --- Check that the Ollama process is running ---
echo "Waiting for Ollama process to start..."
TIMEOUT=10
ELAPSED=0
until pgrep -x ollama &>/dev/null; do
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "Error: Ollama process did not start within ${TIMEOUT}s."
        exit 1
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done
echo "Ollama process is running."

# --- Check client/server version consistency ---
echo "Checking Ollama version..."
VERSION_TIMEOUT=10
VERSION_ELAPSED=0
VERSION_OUTPUT=""
until VERSION_OUTPUT=$(ollama -v 2>/dev/null) && \
      [ "$(echo "$VERSION_OUTPUT" | wc -l | xargs)" -eq 1 ] && \
      [[ "$VERSION_OUTPUT" == ollama\ version\ is\ * ]]; do
    if [ "$VERSION_ELAPSED" -ge "$VERSION_TIMEOUT" ]; then
        VERSION_OUTPUT=$(ollama -v 2>&1)
        echo "Warning: unexpected output from 'ollama -v' — possible client/server version mismatch:"
        echo "$VERSION_OUTPUT"
        exit 1
    fi
    sleep 1
    VERSION_ELAPSED=$((VERSION_ELAPSED + 1))
done
echo "$VERSION_OUTPUT"

exit 0
