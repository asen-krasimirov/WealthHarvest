from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Allow requests from your S3 bucket's domain
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://frontendbucketwealthharvest.s3.eu-central-1.amazonaws.com"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
    allow_credentials=True,
)

@app.get("/data")
async def get_data():
    return {
        "id": 1,
        "name": "FastAPI Example",
        "description": "This data is fetched from the FastAPI backend."
    }
