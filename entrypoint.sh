#!/bin/bash

# 1. Install llama if not already present
if [ ! -f ~/.llama-app/llama ]; then
    curl -LsSf https://llama.app/install.sh | sh
fi

# 2. Start the LLM server in the background and log output
~/.llama-app/llama serve -hf unsloth/SmolLM2-135M-Instruct-GGUF:Q4_K_M --port 8080 --host 0.0.0.0 -ngl all > /tmp/llama.log 2>&1 &
LLAMA_PID=$!

# 3. Launch a clean watchdog loop tracking the exact PID
(
  sleep 60
  while kill -0 $LLAMA_PID 2>/dev/null; do
    CURRENT_TIME=$(date +%s)
    MOD_TIME=$(stat -c %Y /tmp/llama.log 2>/dev/null || echo $CURRENT_TIME)
    AGE=$((CURRENT_TIME - MOD_TIME))
    if [ $AGE -gt 60 ]; then
      echo "Idle for over 60 seconds. Shutting down studio..."
      python3 -c 'from lightning_sdk import Studio; Studio().stop()' 2>/dev/null
      exit 0
    fi
    sleep 10
  done
) &

# 4. Wait on the main server process
wait $LLAMA_PID
