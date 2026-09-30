FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install essential packages and C++ runtime libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    zstd \
    procps \
    libstdc++6 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# 2. Download AWS Lambda Web Adapter directly from GitHub Releases (bypasses ECR rate limits)
RUN mkdir -p /opt/extensions && \
    curl -fsSL -o /opt/extensions/lambda-adapter https://github.com/awslabs/aws-lambda-web-adapter/releases/download/v1.1.0/lambda-adapter-x86_64 && \
    chmod +x /opt/extensions/lambda-adapter

# 3. Install llama.app runner
RUN curl -fsSL https://llama.app/install.sh | sh

# 4. Export binary PATHs
ENV PATH="/root/.llama-app/bin:/root/.llama-app:/root/.local/bin:${PATH}"

# 5. Download SmolLM2-1.7B GGUF (~1.06GB)
RUN curl -fsSL -f -o /model.gguf https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF/resolve/main/smollm2-1.7b-instruct-q4_k_m.gguf

# 6. Configure Web Adapter environment
ENV PORT=8080
ENV AWS_LWA_ASYNC_INIT=true
ENV AWS_LWA_READINESS_CHECK_PATH=/health

# 7. Launch native C++ server bound to 0.0.0.0
CMD ["llama", "serve", "-m", "/model.gguf", "--host", "0.0.0.0", "--port", "8080", "-c", "4096"]
