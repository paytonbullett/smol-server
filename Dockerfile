FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install bare minimum packages needed to fetch and decompress
RUN apt-get update && apt-get install -y curl zstd procps && rm -rf /var/lib/apt/lists/*

# Run llama installer
RUN curl -kLsSf https://llama.app/install.sh | sh

# Download model
RUN curl -kL -o /model.gguf https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf

# Download AWS Lambda Web Adapter directly from GitHub Releases (bypasses ECR rate limits)
RUN mkdir -p /opt/extensions && \
    curl -kL -o /opt/extensions/aws-lambda-adapter https://github.com/awslabs/aws-lambda-web-adapter/releases/download/v0.8.4/lambda-adapter-x86_64 && \
    chmod +x /opt/extensions/aws-lambda-adapter

ENV PORT=8080
ENV AWS_LWA_ASYNC_INIT=true
ENV PATH="/root/.llama-app:/root/.local/bin:${PATH}"

CMD ["llama", "serve", "-m", "/model.gguf", "--host", "0.0.0.0", "--port", "8080", "-c", "2048"]
