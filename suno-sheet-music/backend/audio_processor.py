"""
Audio processor: converts uploaded audio to MIDI using basic-pitch (Spotify).
"""
import os
import subprocess
import tempfile
from pathlib import Path

# Limit audio to 90 seconds to keep processing fast on low-CPU servers
MAX_AUDIO_SECS = 90


def convert_to_wav(input_path: str) -> str:
    """Convert any audio format to mono 22050Hz WAV using ffmpeg, trimmed to MAX_AUDIO_SECS."""
    output_path = str(Path(input_path).with_suffix(".wav"))
    if input_path == output_path:
        output_path = str(Path(input_path).with_stem(Path(input_path).stem + "_conv").with_suffix(".wav"))
    result = subprocess.run(
        [
            "ffmpeg", "-i", input_path,
            "-t", str(MAX_AUDIO_SECS),   # trim to max duration
            "-ar", "22050", "-ac", "1",
            output_path, "-y",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"ffmpeg conversion failed: {result.stderr}")
    return output_path


def process_audio(audio_path: str) -> tuple[str, float]:
    """
    Run basic-pitch on the audio and return (midi_path, tempo_bpm).
    Raises RuntimeError if processing fails.
    """
    # Convert to WAV first (basic-pitch handles most formats but WAV is safest)
    wav_path = convert_to_wav(audio_path)

    try:
        from basic_pitch.inference import predict
        from basic_pitch import ICASSP_2022_MODEL_PATH

        _, midi_data, _ = predict(
            wav_path,
            ICASSP_2022_MODEL_PATH,
            onset_threshold=0.5,
            frame_threshold=0.3,
            minimum_note_length=100,   # ms - avoid noise
            multiple_pitch_bends=False,
            melodia_trick=True,
        )
    except ImportError:
        raise RuntimeError(
            "basic-pitch is not installed. "
            "Run: pip install basic-pitch"
        )
    finally:
        if wav_path != audio_path and os.path.exists(wav_path):
            os.unlink(wav_path)

    # Save MIDI next to audio file
    midi_path = str(Path(audio_path).with_suffix(".mid"))
    midi_data.write(midi_path)

    # Estimate tempo from the MIDI
    tempo = _estimate_tempo(midi_data)

    return midi_path, tempo


def _estimate_tempo(midi_data) -> float:
    """Extract or estimate tempo from a pretty_midi object."""
    try:
        _, tempos = midi_data.get_tempo_changes()
        if len(tempos) > 0:
            return float(tempos[0])
    except Exception:
        pass
    # Fallback: estimate from beat positions
    try:
        beats = midi_data.get_beats()
        if len(beats) >= 2:
            avg_beat = (beats[-1] - beats[0]) / (len(beats) - 1)
            return round(60.0 / avg_beat)
    except Exception:
        pass
    return 120.0
