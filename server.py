from fastapi import FastAPI
from llama_cpp import Llama
from contextlib import asynccontextmanager
from pydantic import BaseModel

# Global variable to hold the model in memory
llm = None

# This tells FastAPI to load the model ONLY AFTER the web server has booted on port 8080
@asynccontextmanager
async def lifespan(app: FastAPI):
    global llm
    print("Starting to load the Qwen model into memory... this will take a moment.")
    
    # Load the model here so it doesn't block Uvicorn startup
    llm = Llama(
        model_path="/var/task/qwen2.5-1.5b-instruct-q4_k_m.gguf",
        n_ctx=2048, 
        verbose=False # Set to True if you want internal llama.cpp logs
    )
    print("Model loaded successfully!")
    
    yield
    
    # Clean up when the container shuts down
    llm = None

# Pass the lifespan function into FastAPI
app = FastAPI(lifespan=lifespan)

# Define a basic request schema
class GenerateRequest(BaseModel):
    prompt: str
    max_tokens: int = 100

@app.get("/")
def health_check():
    return {"status": "ready", "model_loaded": llm is not None}

@app.post("/generate")
def generate(request: GenerateRequest):
    if not llm:
        return {"error": "Model is still loading into RAM, please try again in a few seconds."}
    
    # Run inference
    output = llm(
        prompt=request.prompt, 
        max_tokens=request.max_tokens
    )
    return {"response": output}
