FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://llama.app/install.sh | sh

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/aws-lambda-adapter

EXPOSE 8080
ENV PORT=8080
# ---> ADD THIS LINE TO PREVENT THE 10-SECOND TIMEOUT <---
ENV AWS_LWA_ASYNC_INIT=true

CMD ["bash", "-c", "~/.llama-app/llama serve -hf Qwen/Qwen2.5-1.5B-Instruct-GGUF:Q4_K_M --port 8080 --host 0.0.0.0"]
