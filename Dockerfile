FROM public.ecr.aws/lambda/python:3.10

# Install system dependencies
RUN yum install -y gcc gcc-c++ make git

# Install the CPU version of llama-cpp-python and FastAPI for the server framework
RUN pip install --no-cache-dir fastapi uvicorn[standard] huggingface_hub llama-cpp-python --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu/

# Download the Qwen 1.5B GGUF model during build time so it's baked in
RUN python3 -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='Qwen/Qwen2.5-1.5B-Instruct-GGUF', filename='qwen2.5-1.5b-instruct-q4_k_m.gguf', local_dir='/var/task')"

# Copy the AWS Lambda Web Adapter extension
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/aws-lambda-adapter

# Copy a tiny clean python script that serves the model over port 8080
COPY server.py /var/task/server.py

ENV PORT=8080
ENV AWS_LWA_ASYNC_INIT=true

CMD ["python3", "server.py"]
