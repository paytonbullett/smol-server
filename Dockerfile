FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 8080

CMD ["bash", "-c", "curl -LsSf https://llama.app/install.sh | sh && ~/.llama-app/llama serve -hf Qwen/Qwen2.5-1.5B-Instruct-GGUF:Q4_K_M --port 8080 --host 0.0.0.0 -ngl all"]
