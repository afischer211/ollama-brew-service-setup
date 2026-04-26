#!/bin/bash

# --- Configuration ---
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

# Source plist template: prefer $OLLAMA_HOME/resources, fall back to project resources
if [ -f "$OLLAMA_HOME/resources/homebrew.mxcl.ollama.plist" ]; then
    SOURCE_PLIST="$OLLAMA_HOME/resources/homebrew.mxcl.ollama.plist"
else
    SOURCE_PLIST="$PROJECT_ROOT/resources/homebrew.mxcl.ollama.plist"
fi

# Destination path for the plist file in the user's LaunchAgents directory
PLIST="$HOME/Library/LaunchAgents/homebrew.mxcl.ollama.plist"

# .env location: prefer $OLLAMA_HOME, fall back to project root
if [ -f "$OLLAMA_HOME/.env" ]; then
    ENV_FILE="$OLLAMA_HOME/.env"
    ENV_EXAMPLE_FILE="$OLLAMA_HOME/.env.example"
else
    ENV_FILE="$PROJECT_ROOT/.env"
    ENV_EXAMPLE_FILE="$PROJECT_ROOT/.env.example"
fi


# --- Script Logic ---
# Step 1: If the destination plist does not exist, copy it from the project's resources directory
if [ ! -f "$PLIST" ]; then
  # Ensure the source plist file exists before trying to copy
  if [ ! -f "$SOURCE_PLIST" ]; then
    echo "Error: Source plist template not found at $SOURCE_PLIST"
    exit 1
  fi
  cp "$SOURCE_PLIST" "$PLIST"
  echo "Copied plist template to $PLIST"
fi

# Step 2: Check if the .env file exists. If not, create it from the example file.
if [ ! -f "$ENV_FILE" ]; then
  if [ -f "$ENV_EXAMPLE_FILE" ]; then
    cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
    echo "Copied $ENV_EXAMPLE_FILE to $ENV_FILE"
  else
    echo "Warning: $ENV_FILE not found and no $ENV_EXAMPLE_FILE to copy from. No environment variables will be added."
    # Create an empty .env file to avoid errors later
    touch "$ENV_FILE"
  fi
fi

# Step 3: Make sure the EnvironmentVariables key (a dictionary) exists in the plist
if ! /usr/libexec/PlistBuddy -c "Print :EnvironmentVariables" "$PLIST" &>/dev/null; then
  /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables dict" "$PLIST"
fi

echo "Updating environment variables in $PLIST from $ENV_FILE..."

# Step 4: Parse the .env file and update or add each key/value pair to the plist's EnvironmentVariables
# The `while` loop reads the .env file line by line
while IFS='=' read -r key value || [[ -n "$key" ]];
do
  # Trim leading/trailing whitespace from key and value
  key="$(echo -n "$key" | xargs)"
  value="$(echo -n "$value" | xargs)"

  # Skip empty lines, comment lines (starting with #), and lines without a key
  if [[ -z "$key" ]] || [[ "$key" =~ ^# ]]; then
    continue
  fi

  # Validate the key to ensure it's a valid environment variable name
  if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    echo "Warning: Invalid key '$key' in .env file, skipped."
    continue
  fi

  # Remove optional surrounding quotes (single or double) from the value
  if [[ ${value:0:1} == '"' && ${value: -1} == '"' ]]; then
    value="${value:1:-1}"
  fi
  if [[ ${value:0:1} == "'" && ${value: -1} == "'" ]]; then
    value="${value:1:-1}"
  fi

  # Skip keys that have an empty value after processing
  if [[ -z "$value" ]]; then
    continue
  fi

  # If a key exists, PlistBuddy requires it to be deleted before it can be added again.
  # This ensures the value is updated rather than causing an error.
  if /usr/libexec/PlistBuddy -c "Print :EnvironmentVariables:$key" "$PLIST" &>/dev/null; then
    /usr/libexec/PlistBuddy -c "Delete :EnvironmentVariables:$key" "$PLIST"
  fi
  # Add the key-value pair to the EnvironmentVariables dictionary in the plist.
  # The value is double-quoted to handle spaces. Escape backslashes then double quotes.
  value_escaped="${value//\\/\\\\}"
  value_escaped="${value_escaped//\"/\\\"}"
  /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:$key string \"$value_escaped\"" "$PLIST"
done < "$ENV_FILE"

echo "Successfully updated environment variables in $PLIST"