"""
FastAPI backend for Suno Sheet Music Generator.
"""
import os
import threading
import uuid
from pathlib import Path
from typing import Dict

from fastapi import BackgroundTasks, FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

BASE_DIR    = Path(__file__).parent.parent
UPLOAD_DIR  = BASE_DIR / "uploads"
OUTPUT_DIR  = BASE_DIR / "outputs"
FRONTEND_DIR = BASE_DIR / "frontend"

UPLOAD_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

# ---------------------------------------------------------------------------
# App setup
# ---------------------------------------------------------------------------

app = FastAPI(title="Suno Sheet Music Generator", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Job store  (in-memory; replace with Redis/DB for production)
# ---------------------------------------------------------------------------

jobs: Dict[str, dict] = {}


# ---------------------------------------------------------------------------
# Background processing
# ---------------------------------------------------------------------------

def _run_job(job_id: str, audio_path: str, title: str) -> None:
    """Execute the full audio → sheet music pipeline in a background thread."""
    try:
        jobs[job_id].update(status="processing", progress=10, message="音楽を解析中… (1/3)")

        from audio_processor import process_audio
        midi_path, tempo_bpm = process_audio(audio_path)

        jobs[job_id].update(progress=55, message="楽譜を生成中… (2/3)")

        from sheet_generator import generate_sheets
        job_output_dir = str(OUTPUT_DIR / job_id)
        piano_pdf, guitar_pdf = generate_sheets(
            midi_path, tempo_bpm, title, job_output_dir
        )

        jobs[job_id].update(
            status="completed",
            progress=100,
            message="完成！",
            piano_pdf=piano_pdf,
            guitar_pdf=guitar_pdf,
            tempo_bpm=round(tempo_bpm),
        )

    except Exception as exc:
        jobs[job_id].update(status="failed", message=f"エラー: {exc}")

    finally:
        if os.path.exists(audio_path):
            try:
                os.unlink(audio_path)
            except OSError:
                pass


# ---------------------------------------------------------------------------
# API routes
# ---------------------------------------------------------------------------

ALLOWED_EXTENSIONS = {".mp3", ".wav", ".m4a", ".ogg", ".flac", ".aac"}


@app.post("/api/upload")
async def upload(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    title: str = Form(default="Suno AI Song"),
):
    suffix = Path(file.filename or "audio.mp3").suffix.lower()
    if suffix not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            400,
            f"Unsupported file type '{suffix}'. "
            f"Allowed: {', '.join(ALLOWED_EXTENSIONS)}",
        )

    job_id = str(uuid.uuid4())
    audio_path = str(UPLOAD_DIR / f"{job_id}{suffix}")

    content = await file.read()
    if len(content) == 0:
        raise HTTPException(400, "Uploaded file is empty.")
    if len(content) > 50 * 1024 * 1024:  # 50 MB limit
        raise HTTPException(413, "File too large. Maximum 50 MB.")

    with open(audio_path, "wb") as f:
        f.write(content)

    jobs[job_id] = {
        "status": "queued",
        "progress": 0,
        "message": "キュー待ち…",
        "filename": file.filename,
        "title": title,
    }

    # Use a real thread so the blocking ML model doesn't freeze the event loop
    thread = threading.Thread(target=_run_job, args=(job_id, audio_path, title), daemon=True)
    thread.start()

    return {"job_id": job_id}


@app.get("/api/status/{job_id}")
async def status(job_id: str):
    if job_id not in jobs:
        raise HTTPException(404, "Job not found.")
    j = jobs[job_id]
    return {
        "status":   j.get("status"),
        "progress": j.get("progress", 0),
        "message":  j.get("message", ""),
        "tempo_bpm": j.get("tempo_bpm"),
        "filename": j.get("filename"),
    }


@app.get("/api/download/{job_id}/piano")
async def download_piano(job_id: str):
    return _serve_pdf(job_id, "piano")


@app.get("/api/download/{job_id}/guitar")
async def download_guitar(job_id: str):
    return _serve_pdf(job_id, "guitar")


def _serve_pdf(job_id: str, kind: str) -> FileResponse:
    if job_id not in jobs:
        raise HTTPException(404, "Job not found.")
    job = jobs[job_id]
    if job.get("status") != "completed":
        raise HTTPException(400, "Processing not yet complete.")
    pdf_path = job.get(f"{kind}_pdf", "")
    if not pdf_path or not os.path.exists(pdf_path):
        raise HTTPException(404, f"{kind.title()} PDF not found.")
    safe_title = "".join(c for c in job.get("title", "sheet") if c.isalnum() or c in " _-")
    return FileResponse(
        pdf_path,
        media_type="application/pdf",
        filename=f"{safe_title}_{kind}.pdf",
    )


# ---------------------------------------------------------------------------
# Serve frontend (must be last)
# ---------------------------------------------------------------------------

if FRONTEND_DIR.exists():
    app.mount("/", StaticFiles(directory=str(FRONTEND_DIR), html=True), name="static")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
