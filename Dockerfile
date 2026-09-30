FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install bare minimum dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    zstd \
    procps \
    && rm -rf /var/lib/apt/lists/*

# 2. Copy AWS Lambda Web Adapter extension binary from correct ECR namespace (awsguru)
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/aws-lambda-adapter

# 3. Grant executable permissions to the extension binary
RUN chmod +x /opt/extensions/aws-lambda-adapter

# 4. Install llama.app runner
RUN curl -fsSL https://llama.app/install.sh | sh

# 5. Export path for the llama binary
ENV PATH="/root/.llama-app:/root/.local/bin:${PATH}"

# 6. Download SmolLM2-1.7B GGUF (~1.06GB) during build time
RUN curl -fsSL -o /model.gguf https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF/resolve/main/smollm2-1.7b-instruct-q4_k_m.gguf

# 7. Configure Web Adapter environment
ENV PORT=8080
ENV AWS_LWA_ASYNC_INIT=true

# 8. Launch native C++ server
CMD ["llama", "serve", "-m", "/model.gguf", "--host", "0.0.0.0", "--port", "8080", "-c", "4096"]
