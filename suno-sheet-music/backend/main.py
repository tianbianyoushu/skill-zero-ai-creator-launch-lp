"""
FastAPI backend for AI Gakufu — Sheet Music Generator.
"""
import json
import os
import subprocess
import sys
import threading
import time
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

BASE_DIR     = Path(__file__).parent.parent
UPLOAD_DIR   = BASE_DIR / "uploads"
OUTPUT_DIR   = BASE_DIR / "outputs"
FRONTEND_DIR = BASE_DIR / "frontend"
BACKEND_DIR  = Path(__file__).parent

UPLOAD_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

# ---------------------------------------------------------------------------
# App setup
# ---------------------------------------------------------------------------

app = FastAPI(title="AI Gakufu", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Job store  (in-memory)
# ---------------------------------------------------------------------------

jobs: Dict[str, dict] = {}

JOB_TIMEOUT_SECS = 600  # 10 minutes hard limit


def _watchdog() -> None:
    """Mark jobs that have been running too long as failed."""
    while True:
        time.sleep(30)
        now = time.time()
        for job in list(jobs.values()):
            if job.get("status") == "processing":
                if now - job.get("started_at", now) > JOB_TIMEOUT_SECS:
                    job.update(
                        status="failed",
                        message="タイムアウト：処理に時間がかかりすぎました。短い曲（90秒以内）で再試行してください。",
                    )


threading.Thread(target=_watchdog, daemon=True).start()

# ---------------------------------------------------------------------------
# Background processing — runs ML in a *subprocess* so OOM won't kill the API
# ---------------------------------------------------------------------------

def _run_job(job_id: str, audio_path: str, title: str) -> None:
    """Execute the full pipeline in an isolated subprocess."""
    job_output_dir = str(OUTPUT_DIR / job_id)
    result_json    = str(OUTPUT_DIR / f"{job_id}_result.json")
    worker         = str(BACKEND_DIR / "worker_script.py")

    os.makedirs(job_output_dir, exist_ok=True)

    jobs[job_id].update(
        status="processing",
        progress=10,
        message="音楽を解析中… (1/3)",
        started_at=time.time(),
    )

    try:
        proc = subprocess.Popen(
            [sys.executable, worker, audio_path, title, job_output_dir, result_json],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        # Poll process while updating progress messages
        stages = [
            (30, "音楽を解析中… (1/3)"),
            (55, "楽譜を生成中… (2/3)"),
            (80, "PDF を書き出し中… (3/3)"),
        ]
        stage_idx = 0
        while proc.poll() is None:
            elapsed = time.time() - jobs[job_id]["started_at"]
            # Advance fake progress stage every ~20 seconds
            if stage_idx < len(stages) and elapsed > (stage_idx + 1) * 20:
                pct, msg = stages[stage_idx]
                jobs[job_id].update(progress=pct, message=msg)
                stage_idx += 1
            time.sleep(2)

        returncode = proc.returncode

        # Read result JSON written by worker
        if os.path.exists(result_json):
            with open(result_json) as f:
                result = json.load(f)
            os.unlink(result_json)
        else:
            _, stderr = proc.communicate()
            result = {"ok": False, "error": f"ワーカープロセスが異常終了しました (exit {returncode})"}

        if result.get("ok"):
            jobs[job_id].update(
                status="completed",
                progress=100,
                message="完成！",
                piano_pdf=result["piano_pdf"],
                guitar_pdf=result["guitar_pdf"],
                tempo_bpm=result["tempo_bpm"],
            )
        else:
            jobs[job_id].update(
                status="failed",
                message=f"エラー: {result.get('error', '不明なエラー')}",
            )

    except Exception as exc:
        jobs[job_id].update(status="failed", message=f"サーバーエラー: {exc}")

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
    title: str = Form(default="AI Gakufu Song"),
):
    suffix = Path(file.filename or "audio.mp3").suffix.lower()
    if suffix not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            400,
            f"非対応の形式 '{suffix}'。対応形式: {', '.join(ALLOWED_EXTENSIONS)}",
        )

    job_id     = str(uuid.uuid4())
    audio_path = str(UPLOAD_DIR / f"{job_id}{suffix}")

    content = await file.read()
    if len(content) == 0:
        raise HTTPException(400, "ファイルが空です。")
    if len(content) > 50 * 1024 * 1024:
        raise HTTPException(413, "ファイルが大きすぎます（最大 50 MB）。")

    with open(audio_path, "wb") as f:
        f.write(content)

    jobs[job_id] = {
        "status":   "queued",
        "progress": 0,
        "message":  "キュー待ち…",
        "filename": file.filename,
        "title":    title,
    }

    thread = threading.Thread(
        target=_run_job, args=(job_id, audio_path, title), daemon=True
    )
    thread.start()

    return {"job_id": job_id}


@app.get("/api/status/{job_id}")
async def status(job_id: str):
    if job_id not in jobs:
        raise HTTPException(404, "Job not found.")
    j = jobs[job_id]
    return {
        "status":    j.get("status"),
        "progress":  j.get("progress", 0),
        "message":   j.get("message", ""),
        "tempo_bpm": j.get("tempo_bpm"),
        "filename":  j.get("filename"),
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
        raise HTTPException(400, "処理が完了していません。")
    pdf_path = job.get(f"{kind}_pdf", "")
    if not pdf_path or not os.path.exists(pdf_path):
        raise HTTPException(404, f"{kind} PDF が見つかりません。")
    safe_title = "".join(
        c for c in job.get("title", "sheet") if c.isalnum() or c in " _-"
    )
    return FileResponse(
        pdf_path,
        media_type="application/pdf",
        filename=f"{safe_title}_{kind}.pdf",
    )


@app.get("/api/health")
async def health():
    return {"status": "ok"}


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
