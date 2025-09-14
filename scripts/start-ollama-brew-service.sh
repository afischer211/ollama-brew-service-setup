#!/bin/bash

echo "Update plist and start Ollama service with brew."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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
