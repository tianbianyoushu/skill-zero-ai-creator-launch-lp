"""
Sheet music generator: MIDI → LilyPond → PDF (piano + guitar with tab).
"""
import math
import os
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Tuple


# ---------------------------------------------------------------------------
# Pitch helpers
# ---------------------------------------------------------------------------

NOTE_NAMES = ["c", "cis", "d", "dis", "e", "f", "fis", "g", "gis", "a", "ais", "b"]


def midi_to_lily_pitch(midi_pitch: int) -> str:
    """MIDI number → LilyPond absolute pitch string (e.g. 60 → c')."""
    name = NOTE_NAMES[midi_pitch % 12]
    # MIDI octave: 60 = C4 → octave index 4
    octave = midi_pitch // 12 - 1
    if octave >= 4:
        suffix = "'" * (octave - 3)
    elif octave == 3:
        suffix = ""
    else:
        suffix = "," * (3 - octave)
    return name + suffix


# ---------------------------------------------------------------------------
# Duration helpers
# ---------------------------------------------------------------------------

# (beats, lilypond_string) from longest to shortest
_DURATIONS = [
    (4.000, "1"),
    (3.000, "2."),
    (2.000, "2"),
    (1.500, "4."),
    (1.000, "4"),
    (0.750, "8."),
    (0.500, "8"),
    (0.375, "16."),
    (0.250, "16"),
    (0.125, "32"),
]


def beats_to_lily_dur(beats: float) -> str:
    """Closest standard LilyPond duration for a given beat value."""
    return min(_DURATIONS, key=lambda x: abs(x[0] - beats))[1]


def decompose_beats(beats: float) -> List[Tuple[float, str]]:
    """
    Decompose a duration into a sequence of standard LilyPond durations
    (used for ties across barlines).  Returns list of (beat_value, lily_str).
    """
    result = []
    remaining = round(beats * 32) / 32  # snap to 1/32 beat
    for dur_beats, dur_str in _DURATIONS:
        while remaining >= dur_beats - 0.01:
            result.append((dur_beats, dur_str))
            remaining -= dur_beats
            remaining = round(remaining * 32) / 32
        if remaining < 0.02:
            break
    return result if result else [(0.25, "16")]


# ---------------------------------------------------------------------------
# Note data
# ---------------------------------------------------------------------------

@dataclass
class QNote:
    pitch: int      # MIDI pitch
    start: float    # beat position (float)
    dur: float      # duration in beats


def quantize_notes(raw_notes, tempo_bpm: float, grid: int = 16) -> List[QNote]:
    """
    Convert pretty_midi Note objects to QNote, quantizing to 1/grid beat.
    grid=16 means 16th-note grid.
    """
    beat_dur = 60.0 / tempo_bpm
    grid_secs = beat_dur / grid

    results: List[QNote] = []
    for n in raw_notes:
        start_q = round(n.start / grid_secs) * grid_secs
        end_q   = round(n.end   / grid_secs) * grid_secs
        start_beat = start_q / beat_dur
        dur_beat   = max((end_q - start_q) / beat_dur, 1.0 / grid)
        results.append(QNote(pitch=n.pitch, start=start_beat, dur=dur_beat))

    results.sort(key=lambda n: n.start)
    return results


# ---------------------------------------------------------------------------
# Voice building (non-overlapping chord stream)
# ---------------------------------------------------------------------------

def build_chord_stream(notes: List[QNote]) -> List[Tuple[float, float, List[int]]]:
    """
    Collapse simultaneous notes into chords, ensure non-overlap.
    Returns list of (start_beat, dur_beats, [midi_pitches]).
    """
    if not notes:
        return []

    # Group by rounded start
    buckets: dict = {}
    for n in notes:
        key = round(n.start * 32) / 32
        buckets.setdefault(key, []).append(n)

    events = []
    for start in sorted(buckets):
        group = buckets[start]
        pitches = sorted(set(n.pitch for n in group), reverse=True)[:6]  # max 6 (guitar strings)
        dur = sorted(n.dur for n in group)[len(group) // 2]  # median duration
        events.append((start, dur, pitches))

    # Clip each event so it doesn't overlap with the next
    clipped = []
    for i, (start, dur, pitches) in enumerate(events):
        if i + 1 < len(events):
            next_start = events[i + 1][0]
            dur = min(dur, next_start - start)
        dur = max(dur, 0.125)
        clipped.append((start, dur, pitches))

    return clipped


def fill_rests(
    events: List[Tuple[float, float, List[int]]],
    total_beats: float,
) -> List[Tuple[float, float, List[int]]]:
    """Insert rest events to fill gaps between notes."""
    result: List[Tuple[float, float, List[int]]] = []
    cursor = 0.0
    for start, dur, pitches in events:
        gap = start - cursor
        if gap >= 0.12:
            result.append((cursor, gap, []))
        result.append((start, dur, pitches))
        cursor = start + dur
    tail = total_beats - cursor
    if tail >= 0.12:
        result.append((cursor, tail, []))
    return result


# ---------------------------------------------------------------------------
# LilyPond token generation
# ---------------------------------------------------------------------------

def events_to_lily_tokens(
    events: List[Tuple[float, float, List[int]]],
    beats_per_measure: int = 4,
) -> str:
    """
    Convert flat event list into LilyPond note string with barlines.
    Handles ties across measure boundaries.
    """
    tokens: List[str] = []
    measure_pos = 0.0   # beats elapsed in current measure
    bpm_f = float(beats_per_measure)

    for start, dur, pitches in events:
        remaining_dur = dur
        first = True

        while remaining_dur > 0.02:
            # How much space left in current measure?
            space = bpm_f - measure_pos
            chunk = min(remaining_dur, space)

            parts = decompose_beats(chunk)

            for i, (_, lily_dur) in enumerate(parts):
                is_last_part = (i == len(parts) - 1)
                needs_tie = (not is_last_part) or (remaining_dur - chunk > 0.02)

                if not pitches:
                    tokens.append(f"r{lily_dur}")
                elif len(pitches) == 1:
                    p = midi_to_lily_pitch(pitches[0])
                    tok = f"{p}{lily_dur}"
                    if needs_tie and not is_last_part:
                        tok += "~"
                    tokens.append(tok)
                    # Cross-measure tie (single note only)
                    if needs_tie and is_last_part and remaining_dur - chunk > 0.02:
                        tokens[-1] += "~"
                else:
                    ps = " ".join(midi_to_lily_pitch(p) for p in pitches)
                    tok = f"<{ps}>{lily_dur}"
                    tokens.append(tok)

            # Advance position
            measure_pos += chunk
            remaining_dur -= chunk
            remaining_dur = round(remaining_dur * 32) / 32

            if measure_pos >= bpm_f - 0.02:
                tokens.append("|")
                measure_pos = 0.0
            first = False

    # Close final measure if needed
    if measure_pos > 0.02:
        remaining_in_measure = bpm_f - measure_pos
        if remaining_in_measure > 0.02:
            for _, dur_str in decompose_beats(remaining_in_measure):
                tokens.append(f"r{dur_str}")
        tokens.append("|")

    return "\n  ".join(tokens)


# ---------------------------------------------------------------------------
# Guitar range adaptation
# ---------------------------------------------------------------------------

GUITAR_LOW  = 40   # E2
GUITAR_HIGH = 76   # E5

def adapt_to_guitar(notes: List[QNote]) -> List[QNote]:
    """Transpose notes into the guitar's sounding range by octave shifts."""
    result = []
    for n in notes:
        p = n.pitch
        while p > GUITAR_HIGH:
            p -= 12
        while p < GUITAR_LOW:
            p += 12
        result.append(QNote(pitch=p, start=n.start, dur=n.dur))
    return result


# ---------------------------------------------------------------------------
# LilyPond file builders
# ---------------------------------------------------------------------------

def _header(title: str, subtitle: str, tempo_bpm: float, time_sig: Tuple[int, int]) -> str:
    num, den = time_sig
    return f"""\
\\version "2.24.0"

\\header {{
  title = "{_escape_lily(title)}"
  subtitle = "{subtitle}"
  composer = "Suno AI"
  tagline = "Generated by Suno Sheet Music"
}}

globalSettings = {{
  \\tempo 4 = {int(tempo_bpm)}
  \\time {num}/{den}
  \\key c \\major
}}
"""


def _escape_lily(s: str) -> str:
    return s.replace('"', '\\"').replace("\\", "\\\\")


def build_piano_lily(
    treble_events: List[Tuple[float, float, List[int]]],
    bass_events:   List[Tuple[float, float, List[int]]],
    total_beats: float,
    tempo_bpm: float,
    title: str,
    time_sig: Tuple[int, int] = (4, 4),
) -> str:
    bpm = time_sig[0]
    treble_tokens = events_to_lily_tokens(fill_rests(treble_events, total_beats), bpm)
    bass_tokens   = events_to_lily_tokens(fill_rests(bass_events,   total_beats), bpm)

    header = _header(title, "Piano Arrangement", tempo_bpm, time_sig)
    return header + f"""
trebleVoice = {{
  \\globalSettings
  {treble_tokens}
}}

bassVoice = {{
  \\globalSettings
  {bass_tokens}
}}

\\score {{
  \\new PianoStaff \\with {{
    instrumentName = "Piano"
  }} <<
    \\new Staff \\with {{ \\clef treble }} \\trebleVoice
    \\new Staff \\with {{ \\clef bass   }} \\bassVoice
  >>
  \\layout {{
    \\context {{
      \\Score
      \\override SpacingSpanner.common-shortest-duration = #(ly:make-moment 1/8)
    }}
  }}
}}
"""


def build_guitar_lily(
    guitar_events: List[Tuple[float, float, List[int]]],
    total_beats: float,
    tempo_bpm: float,
    title: str,
    time_sig: Tuple[int, int] = (4, 4),
) -> str:
    bpm = time_sig[0]
    guitar_tokens = events_to_lily_tokens(fill_rests(guitar_events, total_beats), bpm)

    header = _header(title, "Guitar Arrangement (Standard Notation + Tab)", tempo_bpm, time_sig)
    return header + f"""
guitarNotes = {{
  \\globalSettings
  {guitar_tokens}
}}

\\score {{
  <<
    \\new Staff \\with {{
      instrumentName = "Guitar"
    }} {{
      \\clef "treble_8"
      \\guitarNotes
    }}
    \\new TabStaff \\with {{
      stringTunings = #guitar-tuning
    }} \\guitarNotes
  >>
  \\layout {{
    \\context {{
      \\Score
      \\override SpacingSpanner.common-shortest-duration = #(ly:make-moment 1/8)
    }}
  }}
}}
"""


# ---------------------------------------------------------------------------
# LilyPond render
# ---------------------------------------------------------------------------

def render_lily_to_pdf(lily_code: str, output_pdf_path: str) -> str:
    """Write LilyPond code to temp file, render to PDF, return output path."""
    output_base = str(Path(output_pdf_path).with_suffix(""))  # strip .pdf

    with tempfile.NamedTemporaryFile(
        suffix=".ly", delete=False, mode="w", encoding="utf-8"
    ) as f:
        f.write(lily_code)
        ly_path = f.name

    try:
        result = subprocess.run(
            ["lilypond", "--pdf", f"--output={output_base}", ly_path],
            capture_output=True,
            text=True,
            timeout=120,
        )
    except FileNotFoundError:
        raise RuntimeError(
            "LilyPond is not installed or not in PATH. "
            "Install from https://lilypond.org/download.html"
        )
    except subprocess.TimeoutExpired:
        raise RuntimeError("LilyPond timed out after 120 seconds.")
    finally:
        if os.path.exists(ly_path):
            os.unlink(ly_path)

    if result.returncode != 0:
        # Surface the LilyPond error
        raise RuntimeError(
            f"LilyPond failed (exit {result.returncode}):\n{result.stderr[-2000:]}"
        )

    final_pdf = output_base + ".pdf"
    if not os.path.exists(final_pdf):
        raise RuntimeError(f"LilyPond ran but PDF not found at {final_pdf}")

    return final_pdf


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def generate_sheets(
    midi_path: str,
    tempo_bpm: float,
    title: str,
    output_dir: str,
) -> Tuple[str, str]:
    """
    Generate piano.pdf and guitar.pdf from a MIDI file.
    Returns (piano_pdf_path, guitar_pdf_path).
    """
    import pretty_midi

    midi = pretty_midi.PrettyMIDI(midi_path)
    if os.path.exists(midi_path):
        os.unlink(midi_path)

    # Collect all non-drum notes
    raw_notes = []
    for inst in midi.instruments:
        if not inst.is_drum:
            raw_notes.extend(inst.notes)

    if not raw_notes:
        raise RuntimeError("No pitched notes detected in the audio.")

    raw_notes.sort(key=lambda n: n.start)

    # Quantize
    qnotes = quantize_notes(raw_notes, tempo_bpm, grid=16)

    # Total song length (in beats), cap at 500 measures
    end_time = max(n.start + n.dur for n in qnotes) if qnotes else 4.0
    total_beats = min(math.ceil(end_time / 4) * 4, 500 * 4)

    # Piano voices
    treble_notes = [n for n in qnotes if n.pitch >= 60]
    bass_notes   = [n for n in qnotes if n.pitch <  60]

    treble_events = build_chord_stream(treble_notes)
    bass_events   = build_chord_stream(bass_notes)

    # Guitar voice (adapted to guitar range)
    guitar_notes  = adapt_to_guitar(qnotes)
    guitar_events = build_chord_stream(guitar_notes)

    os.makedirs(output_dir, exist_ok=True)

    # --- Piano PDF ---
    piano_lily = build_piano_lily(
        treble_events, bass_events, total_beats, tempo_bpm, title
    )
    piano_pdf = render_lily_to_pdf(piano_lily, os.path.join(output_dir, "piano.pdf"))

    # --- Guitar PDF ---
    guitar_lily = build_guitar_lily(
        guitar_events, total_beats, tempo_bpm, title
    )
    guitar_pdf = render_lily_to_pdf(guitar_lily, os.path.join(output_dir, "guitar.pdf"))

    return piano_pdf, guitar_pdf
