"""
Audio processor: converts uploaded audio to MIDI using basic-pitch (Spotify).
"""
import os
import subprocess
from pathlib import Path

def convert_to_wav(input_path: str) -> str:
    """Convert any audio to mono 22050Hz WAV (full length)."""
    output_path = str(Path(input_path).with_suffix(".wav"))
    if input_path == output_path:
        output_path = str(
            Path(input_path)
            .with_stem(Path(input_path).stem + "_conv")
            .with_suffix(".wav")
        )
    result = subprocess.run(
        [
            "ffmpeg", "-i", input_path,
            "-ar", "22050", "-ac", "1",
            "-acodec", "pcm_s16le",
            output_path, "-y",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"ffmpeg 変換失敗: {result.stderr[-500:]}")
    return output_path


def process_audio(audio_path: str) -> tuple[str, float]:
    """
    Run basic-pitch on the audio and return (midi_path, tempo_bpm).
    """
    wav_path = convert_to_wav(audio_path)

    try:
        # Suppress TF logs before import
        os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"

        from basic_pitch.inference import predict
        from basic_pitch import ICASSP_2022_MODEL_PATH

        _, midi_data, _ = predict(
            wav_path,
            ICASSP_2022_MODEL_PATH,
            onset_threshold=0.5,
            frame_threshold=0.3,
            minimum_note_length=100,
            multiple_pitch_bends=False,
            melodia_trick=True,
        )
    except ImportError:
        raise RuntimeError("basic-pitch がインストールされていません。")
    finally:
        if wav_path != audio_path and os.path.exists(wav_path):
            try:
                os.unlink(wav_path)
            except OSError:
                pass

    midi_path = str(Path(audio_path).with_suffix(".mid"))
    midi_data.write(midi_path)

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
    try:
        beats = midi_data.get_beats()
        if len(beats) >= 2:
            avg_beat = (beats[-1] - beats[0]) / (len(beats) - 1)
            return round(60.0 / avg_beat)
    except Exception:
        pass
    return 120.0
