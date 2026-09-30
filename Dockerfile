FROM ubuntu:22.04

# 1. Run the official auto-detect install script (your exact command)
RUN curl -LsSf https://llama.app/install.sh | sh

# 2. Download the model DURING the build so it is baked into the image
# (If we do not do this, Lambda will try to download 1GB every time it wakes up)
RUN curl -L -o /model.gguf https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf

# 3. Attach the AWS Web Adapter to proxy traffic to the binary
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/aws-lambda-adapter

# 4. Configure the adapter and add the installed binary to the system PATH
ENV PORT=8080
ENV AWS_LWA_ASYNC_INIT=true
ENV PATH="/root/.llama-app:${PATH}"

# 5. Run the native C++ web server directly
CMD ["llama", "serve", "-m", "/model.gguf", "--host", "0.0.0.0", "--port", "8080", "-c", "2048"]
