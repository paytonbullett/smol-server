FROM ubuntu:22.04

# Install basic dependencies and curl
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install llama-app using your preferred script
RUN curl -LsSf https://llama.app/install.sh | sh

# Copy the AWS Lambda Web Adapter so Lambda can route HTTP traffic to port 8080
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /opt/extensions/aws-lambda-adapter /opt/extensions/aws-lambda-adapter

EXPOSE 8080
ENV PORT=8080

# Run the llama-app server pointing to Qwen 1.5B (CPU mode since Lambda has no GPU)
CMD ["bash", "-c", "~/.llama-app/llama serve -hf Qwen/Qwen2.5-1.5B-Instruct-GGUF:Q4_K_M --port 8080 --host 0.0.0.0"]
