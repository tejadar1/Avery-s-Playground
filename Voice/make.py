"""Records Coco's lines with Kokoro, a free open-source voice, into AverysPlayground/Voice/<key>.mp3.

Runs on GitHub's Linux machines (.github/workflows/build.yml, "voice" input). Voice/voice.txt holds the Kokoro
voice and how much to raise its pitch, like "af_heart 1.25". Records only lines without a file yet, removes files
for lines that are gone, and re-records everything when voice.txt changes.
`--samples` instead records a few lines in several voices and pitches to Voice/samples/ for choosing one.
The key is the first 16 hex digits of the line's SHA-256, matching Speaker.key(for:) in the app.
"""
import hashlib
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
import soundfile
from kokoro import KPipeline

here = Path(__file__).resolve().parent
pipeline = KPipeline(lang_code="a")  # American English


def record(line, voice, pitch, path):
    audio = np.concatenate([np.asarray(chunk) for _, _, chunk in pipeline(line, voice=voice)])
    with tempfile.NamedTemporaryFile(suffix=".wav") as wav:
        soundfile.write(wav.name, audio, 24000)
        # Raise the pitch for a cartoon voice, keeping the speed (a touch quicker, for bounce).
        tempo = 1.08 / pitch
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav.name,
                        "-af", f"asetrate={int(24000 * pitch)},aresample=24000,atempo={tempo:.3f}",
                        "-b:a", "64k", str(path)], check=True)


if "--samples" in sys.argv:
    out = here / "samples"
    out.mkdir(exist_ok=True)
    line = "Holy guacamole! Snap snap! I ate a crayon once. It tasted purple! Let's paint your nails!"
    for voice in ["af_heart", "af_bella", "af_nicole", "af_sky", "af_nova", "af_jessica"]:
        for pitch in [1.0, 1.2, 1.35]:
            record(line, voice, pitch, out / f"{voice}-{pitch}.mp3")
    sys.exit()

out = here.parent / "AverysPlayground" / "Voice"
out.mkdir(exist_ok=True)
voice, pitch = (here / "voice.txt").read_text().split()
made_with = out / "voice-id.txt"
if made_with.exists() and made_with.read_text().split() != [voice, pitch]:
    for old in out.glob("*.mp3"):
        old.unlink()
made_with.write_text(f"{voice} {pitch}\n")


def key(line):
    return hashlib.sha256(line.encode()).hexdigest()[:16]


wanted = {key(l): l for l in (here / "lines.txt").read_text().splitlines() if l.strip()}
for old in out.glob("*.mp3"):
    if old.stem not in wanted:
        old.unlink()
todo = [(k, l) for k, l in wanted.items() if not (out / f"{k}.mp3").exists()]
print(f"{len(wanted)} lines, {len(todo)} to record with {voice} at pitch {pitch}")
for n, (k, line) in enumerate(todo, 1):
    record(line, voice, float(pitch), out / f"{k}.mp3")
    if n % 100 == 0:
        print(f"{n} recorded")
print("Done")
