# 1. Use the standard Python Docker image (No AWS background traps)
FROM python:3.10-slim

# 2. Install system dependencies (using apt-get instead of yum)
RUN apt-get update && \
    apt-get install -y gcc g++ make git && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip

# 3. Install Python packages (uvicorn without [standard] to avoid Rust errors)
RUN pip install --no-cache-dir fastapi uvicorn huggingface_hub llama-cpp-python \
    --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu/

# 4. Set the working directory
WORKDIR /var/task

# 5. Download the model during build time
RUN python3 -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='Qwen/Qwen2.5-1.5B-Instruct-GGUF', filename='qwen2.5-1.5b-instruct-q4_k_m.gguf', local_dir='/var/task')"

# 6. Copy the AWS Web Adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/aws-lambda-adapter

# 7. Copy your application code
COPY server.py /var/task/server.py

# 8. Configure the Web Adapter to allow long startup times
ENV PORT=8080
ENV AWS_LWA_ASYNC_INIT=true

# 9. Start Uvicorn directly
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8080"]
