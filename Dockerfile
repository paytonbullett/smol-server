FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install bare minimum packages needed to fetch and decompress
RUN apt-get update && apt-get install -y curl zstd procps && rm -rf /var/lib/apt/lists/*

# Run installer with -k to skip SSL checks completely
RUN curl -kLsSf https://llama.app/install.sh | sh

# Download model with -k to skip SSL checks completely
RUN curl -kL -o /model.gguf https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf

# Attach AWS Lambda Web Adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/aws-lambda-adapter

ENV PORT=8080
ENV AWS_LWA_ASYNC_INIT=true
ENV PATH="/root/.llama-app:/root/.local/bin:${PATH}"

CMD ["llama", "serve", "-m", "/model.gguf", "--host", "0.0.0.0", "--port", "8080", "-c", "2048"]
