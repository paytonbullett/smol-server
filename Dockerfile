FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install essential packages including ca-certificates for secure HTTPS
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    zstd \
    procps \
    && rm -rf /var/lib/apt/lists/*

# 2. Copy AWS Lambda Web Adapter from the official public ECR image
COPY --from=public.ecr.aws/awslabs/aws-lambda-web-adapter:0.8.4 /lambda-adapter /opt/extensions/lambda-adapter

# 3. Install llama.app
RUN curl -fsSL https://llama.app/install.sh | sh

# 4. Expose llama binary path
ENV PATH="/root/.llama-app:/root/.local/bin:${PATH}"

# 5. Download model securely (-L follows Hugging Face CDN redirects)
RUN curl -fsSL -o /model.gguf https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf

ENV PORT=8080
ENV AWS_LWA_ASYNC_INIT=true

CMD ["llama", "serve", "-m", "/model.gguf", "--host", "0.0.0.0", "--port", "8080", "-c", "2048"]
