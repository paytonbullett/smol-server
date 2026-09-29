import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from llama_cpp import Llama

app = FastAPI()

# Load the model from the local directory on startup
print("Loading model...")
llm = Llama(
    model_path="/var/task/qwen2.5-1.5b-instruct-q4_k_m.gguf",
    n_ctx=2048,
    n_threads=4,
    verbose=False
)
print("Model loaded successfully!")

class ChatRequest(BaseModel):
    messages: list

@app.post("/v1/chat/completions")
def chat_completions(body: ChatRequest):
    try:
        # Convert OpenAI format messages to prompt format
        prompt = ""
        for msg in body.messages:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            prompt += f"<|im_start|>{role}\n{content}<|im_end|>\n"
        prompt += "<|im_start|>assistant\n"

        output = llm(
            prompt,
            max_tokens=256,
            stop=["<|im_end|>"]
        )
        
        reply = output["choices"][0]["text"]
        
        # Return OpenAI-compatible response structure
        return {
            "choices": [{
                "message": {"role": "assistant", "content": reply}
            }]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
