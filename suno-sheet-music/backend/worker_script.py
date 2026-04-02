"""
Standalone worker script: audio → MIDI → PDF
Called as a subprocess from main.py so OOM crashes don't kill the API server.

Usage:
    python worker_script.py <audio_path> <title> <output_dir> <result_json_path>
"""
import json
import os
import sys
from pathlib import Path

# Suppress TensorFlow verbose logs
os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "3")
os.environ.setdefault("PYTHONWARNINGS", "ignore")


def main():
    if len(sys.argv) != 5:
        print(json.dumps({"error": "Usage: worker_script.py <audio> <title> <out_dir> <result_json>"}))
        sys.exit(1)

    audio_path   = sys.argv[1]
    title        = sys.argv[2]
    output_dir   = sys.argv[3]
    result_path  = sys.argv[4]

    def write_result(data: dict):
        with open(result_path, "w") as f:
            json.dump(data, f)

    try:
        # ── Step 1: audio → MIDI ──────────────────────────────────────────
        from audio_processor import process_audio
        midi_path, tempo_bpm = process_audio(audio_path)

        # ── Step 2: MIDI → PDF ───────────────────────────────────────────
        from sheet_generator import generate_sheets
        piano_pdf, guitar_pdf = generate_sheets(midi_path, tempo_bpm, title, output_dir)

        write_result({
            "ok": True,
            "piano_pdf":  piano_pdf,
            "guitar_pdf": guitar_pdf,
            "tempo_bpm":  round(tempo_bpm),
        })

    except Exception as exc:
        write_result({"ok": False, "error": str(exc)})
        sys.exit(1)


if __name__ == "__main__":
    main()
