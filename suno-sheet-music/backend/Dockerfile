FROM python:3.11-slim

# System dependencies: ffmpeg + LilyPond
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    lilypond \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps first (cache layer)
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source
COPY backend/ ./backend/
COPY frontend/ ./frontend/

# Create data directories
RUN mkdir -p uploads outputs

EXPOSE 8000

CMD ["python", "-m", "uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
