FROM python:3.10-slim

RUN apt-get update && \
    apt-get install -y gcc g++ make git && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip

RUN pip install --no-cache-dir fastapi uvicorn huggingface_hub llama-cpp-python \
    --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu/

WORKDIR /var/task

# Download model
RUN python3 -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='Qwen/Qwen2.5-1.5B-Instruct-GGUF', filename='qwen2.5-1.5b-instruct-q4_k_m.gguf', local_dir='/var/task')"

# AWS Lambda Web Adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/aws-lambda-adapter

# Copy both application code and debug script
COPY server.py /var/task/server.py
COPY debug_launcher.py /var/task/debug_launcher.py

ENV PORT=8080
ENV AWS_LWA_ASYNC_INIT=true
ENV PYTHONUNBUFFERED=1

# Run the debug launcher instead of raw uvicorn
CMD ["python3", "/var/task/debug_launcher.py"]
