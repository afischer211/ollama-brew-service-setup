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
  echo "$PLIST is not found."
  exit 1
fi


brew services --file $PLIST start ollama

exit 0
