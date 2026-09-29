FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

# Install basic dependencies, python for the SDK shutdown call, and procps for process management
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    python3 \
    procps \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 8080

# Launch server in background, monitor log activity, and auto-shutdown after 60s of silence
CMD ["bash", "-c", "curl -LsSf https://llama.app/install.sh | sh && \
(~/.llama-app/llama serve -hf unsloth/SmolLM2-135M-Instruct-GGUF:Q4_K_M --port 8080 --host 0.0.0.0 -ngl all > /tmp/llama.log 2>&1 &) && \
( \
  sleep 60; \
  while kill -0 $(pgrep -f llama) 2>/dev/null; do \
    CURRENT_TIME=$(date +%s); \
    MOD_TIME=$(stat -c %Y /tmp/llama.log 2>/dev/null || echo $CURRENT_TIME); \
    AGE=$((CURRENT_TIME - MOD_TIME)); \
    if [ $AGE -gt 60 ]; then \
      echo 'Idle for over 60 seconds. Shutting down studio...'; \
      python3 -c 'from lightning_sdk import Studio; Studio().stop()' 2>/dev/null; \
      exit 0; \
    fi; \
    sleep 10; \
  done \
) & \
wait"]
