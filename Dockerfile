FROM public.ecr.aws/lambda/python:3.10

# Install system dependencies
RUN yum install -y gcc gcc-c++ make git

# Upgrade pip to ensure it downloads pre-built manylinux wheels instead of building from source
RUN pip install --upgrade pip

# Install FastAPI, base Uvicorn, and llama-cpp-python for CPU
# (Dropping [standard] prevents pip from trying to compile Rust dependencies)
RUN pip install --no-cache-dir fastapi uvicorn huggingface_hub llama-cpp-python \
    --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu/

# Download the model during build time
RUN python3 -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='Qwen/Qwen2.5-1.5B-Instruct-GGUF', filename='qwen2.5-1.5b-instruct-q4_k_m.gguf', local_dir='/var/task')"

# --- ADD THE AWS LAMBDA WEB ADAPTER ---
# Copy the binary directly from the official AWS public ECR repo
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/aws-lambda-adapter

# Copy your python server code
COPY server.py /var/task/server.py

# Configure the Web Adapter
ENV PORT=8080
ENV AWS_LWA_ASYNC_INIT=true

# --- THE STARTUP FIX ---
# 1. Clear the default AWS Lambda entrypoint so it doesn't try to look for a standard handler function
ENTRYPOINT []

# 2. Start Uvicorn directly. The Web Adapter will automatically route Lambda requests to this local server.
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8080"]
