#!/bin/bash

echo "Stopping Ollama service..."
brew services stop ollama

echo "Waiting for Ollama process to exit..."
TIMEOUT=10
ELAPSED=0
while pgrep -x ollama &>/dev/null; do
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "Warning: Ollama process is still running after ${TIMEOUT}s."
        echo "You may need to stop it manually: kill $(pgrep -x ollama)"
        exit 1
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

echo "Ollama stopped successfully."
exit 0
