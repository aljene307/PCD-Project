from dotenv import load_dotenv
load_dotenv()

import traceback
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from database import init_db
from advisor_router import router as advisor_router
from crop_router import router as crop_router
from lab_router import router as lab_router
import os
print(repr(os.getenv("GROQ_API_KEY")))
app = FastAPI(title="Crop Advisor API", version="4.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    traceback.print_exc()
    return JSONResponse(status_code=500, content={"detail": str(exc)})

@app.on_event("startup")
def startup():
    init_db()

app.include_router(advisor_router)
app.include_router(crop_router)
app.include_router(lab_router)

@app.get("/health")
async def health():
    return {"status": "ok"}