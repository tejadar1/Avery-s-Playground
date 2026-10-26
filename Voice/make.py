"""Records Coco's lines with ElevenLabs into AverysPlayground/Voice/<key>.mp3.

Run by .github/workflows/voice.yml with ELEVENLABS_API_KEY set. Records only lines without a file yet,
and removes files for lines that are gone. Changing Voice/voice.txt re-records everything.
The key is the first 16 hex digits of the line's SHA-256, matching Speaker.recording(for:) in the app.
"""
import hashlib
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

here = Path(__file__).resolve().parent
out = here.parent / "AverysPlayground" / "Voice"
out.mkdir(exist_ok=True)
voice = (here / "voice.txt").read_text().strip()
made_with = out / "voice-id.txt"
if made_with.exists() and made_with.read_text().strip() != voice:
    for old in out.glob("*.mp3"):
        old.unlink()
made_with.write_text(voice + "\n")


def key(line):
    return hashlib.sha256(line.encode()).hexdigest()[:16]


lines = [l for l in (here / "lines.txt").read_text().splitlines() if l.strip()]
wanted = {key(l): l for l in lines}
for old in out.glob("*.mp3"):
    if old.stem not in wanted:
        old.unlink()

todo = [(k, l) for k, l in wanted.items() if not (out / f"{k}.mp3").exists()]
print(f"{len(lines)} lines, {len(todo)} to record")
for n, (k, line) in enumerate(todo, 1):
    request = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_64",
        data=json.dumps({
            "text": line,
            "model_id": "eleven_turbo_v2_5",
            "voice_settings": {"stability": 0.4, "similarity_boost": 0.8, "style": 0.4},
        }).encode(),
        headers={"xi-api-key": os.environ["ELEVENLABS_API_KEY"], "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            (out / f"{k}.mp3").write_bytes(response.read())
    except urllib.error.HTTPError as error:
        # Out of credits or a bad key: keep what's recorded so far, the rest falls back to the iPad's voice.
        print(f"Stopped at line {n}: {error.code} {error.read().decode()[:300]}")
        sys.exit(1 if n == 1 else 0)
    if n % 50 == 0:
        print(f"{n} recorded")
print("Done")
