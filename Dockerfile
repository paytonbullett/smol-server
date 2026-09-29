FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install llama-app
RUN curl -LsSf https://llama.app/install.sh | sh

# --- FIX IS HERE: Correct syntax to copy the AWS Lambda Web Adapter ---
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/aws-lambda-adapter

EXPOSE 8080
ENV PORT=8080

# Run the llama-app server pointing to Qwen 1.5B
CMD ["bash", "-c", "~/.llama-app/llama serve -hf Qwen/Qwen2.5-1.5B-Instruct-GGUF:Q4_K_M --port 8080 --host 0.0.0.0"]
