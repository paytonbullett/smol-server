FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install bare minimum dependencies (including ca-certificates for secure HTTPS)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    zstd \
    procps \
    && rm -rf /var/lib/apt/lists/*

# 2. Copy AWS Lambda Web Adapter extension binary
COPY --from=public.ecr.aws/awslabs/aws-lambda-web-adapter:0.8.4 /lambda-adapter /opt/extensions/aws-lambda-adapter

# 3. CRITICAL FIX: Explicitly grant executable permissions to the extension binary
RUN chmod +x /opt/extensions/aws-lambda-adapter

# 4. Install llama.app (C++ binary runner)
RUN curl -fsSL https://llama.app/install.sh | sh

# 5. Export path for the llama binary
ENV PATH="/root/.llama-app:/root/.local/bin:${PATH}"

# 6. Download model during build time
RUN curl -fsSL -o /model.gguf https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf

# 7. Configure Web Adapter environment
ENV PORT=8080
ENV AWS_LWA_ASYNC_INIT=true

# 8. Launch native C++ server
CMD ["llama", "serve", "-m", "/model.gguf", "--host", "0.0.0.0", "--port", "8080", "-c", "2048"]
