FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies, git, cmake, build-tools, and curl
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone and build llama.cpp directly so we get the standard clean HTTP server (llama-server)
RUN git clone https://github.com/ggerganov/llama.cpp.git && \
    cd llama.cpp && \
    cmake -B build && \
    cmake --build build --config Release -j4

# Copy the AWS Lambda Web Adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/aws-lambda-adapter

EXPOSE 8080
ENV PORT=8080
ENV AWS_LWA_ASYNC_INIT=true

# Run the standard llama-server binary directly, downloading the model on the fly
CMD ["/llama.cpp/build/bin/llama-server", "-hf", "Qwen/Qwen2.5-1.5B-Instruct-GGUF:Q4_K_M", "--port", "8080", "--host", "0.0.0.0", "-c", "2048", "-t", "4"]
