"""Records Coco's lines with Kokoro (the kokoro-onnx build), a free open-source voice, into AverysPlayground/Voice/<key>.mp3.

Runs on GitHub's Linux machines (.github/workflows/build.yml, "voice" input). Voice/voice.txt holds the Kokoro
voice and how much to raise its pitch, one line per language: English, then Spanish, like "af_heart 1.25".
Lines starting with "es:" are Spanish. Records only lines without a file yet, removes files for lines that are
gone, and re-records a language's lines when its voice changes.
`--samples` instead records a few lines in several voices and pitches to Voice/samples/ for choosing one.
The key is the first 16 hex digits of the line's SHA-256 ("es:" included), matching Speaker.recording(for:language:).
"""
import hashlib
import subprocess
import sys
import tempfile
from pathlib import Path

import soundfile
from kokoro_onnx import Kokoro

here = Path(__file__).resolve().parent
# Model files downloaded by the workflow from the kokoro-onnx releases.
kokoro = Kokoro(str(here / "kokoro-v1.0.onnx"), str(here / "voices-v1.0.bin"))


def letter_sound(ipa, voice):
    """A letter's sound ("sound:æ" lines) from its IPA. Stops get a soft vowel so they can be heard; held sounds are held."""
    phonemes = ipa + ("ə" if ipa in {"b", "d", "ɡ", "k", "p", "t", "h", "w"} else "ː" if ipa in {"f", "s", "v", "n"} else "")
    audio, rate = kokoro.create(phonemes, voice=voice, speed=0.85, lang="en-us", is_phonemes=True)
    if len(audio) < rate * 0.1 or abs(audio).max() < 0.02:
        raise ValueError(f"no sound for {ipa}")
    return audio, rate


def record(line, voice, pitch, path, lang="en-us"):
    if line.startswith("sound:"):
        try:
            audio, rate = letter_sound(line.removeprefix("sound:"), voice)
        except Exception as error:  # the app falls back to the device voice for this sound
            print(f"Skipped {line}: {error}")
            return
    else:
        audio, rate = kokoro.create(line, voice=voice, speed=1.0, lang=lang)
    with tempfile.NamedTemporaryFile(suffix=".wav") as wav:
        soundfile.write(wav.name, audio, rate)
        # Raise the pitch for a cartoon voice, keeping the speed (a touch quicker, for bounce).
        tempo = 1.08 / pitch
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav.name,
                        "-af", f"asetrate={int(24000 * pitch)},aresample=24000,atempo={tempo:.3f}",
                        "-b:a", "64k", str(path)], check=True)


if "--samples" in sys.argv:
    out = here / "samples"
    out.mkdir(exist_ok=True)
    # Storyteller voices for the books: warm women's voices at their own pitch, reading the same page.
    line = "Once upon a time, three little pigs went out to build three little houses. The first pig built a house of straw."
    for voice in ["af_bella", "af_heart", "af_nicole", "af_sarah", "af_aoede", "af_kore", "bf_emma", "bf_isabella", "ef_dora"]:
        for pitch in [1.0, 1.08]:
            record(line, voice, pitch, out / f"{voice}-{pitch}.mp3")
    sys.exit()

out = here.parent / "AverysPlayground" / "Voice"
out.mkdir(exist_ok=True)


def key(line):
    return hashlib.sha256(line.encode()).hexdigest()[:16]


all_lines = [l for l in (here / "lines.txt").read_text().splitlines() if l.strip()]
wanted = {key(l): l for l in all_lines}
for old in out.glob("*.mp3"):
    if old.stem not in wanted:
        old.unlink()

voices = (here / "voice.txt").read_text().splitlines()
for (voice, pitch), lang, suffix, mine in [
    (voices[0].split(), "en-us", "", lambda l: not l.startswith(("es:", "dora:"))),
    (voices[1].split(), "es", "-es", lambda l: l.startswith("es:")),
    # The friends, and the English meanings of Spanish words: Dora's voice speaking English
    (voices[1].split(), "en-us", "-dora", lambda l: l.startswith("dora:")),
]:
    keys = {k: l for k, l in wanted.items() if mine(l)}
    made_with = out / f"voice-id{suffix}.txt"
    if made_with.exists() and made_with.read_text().split() != [voice, pitch]:
        for k in keys:
            (out / f"{k}.mp3").unlink(missing_ok=True)
    made_with.write_text(f"{voice} {pitch}\n")
    todo = [(k, l) for k, l in keys.items() if not (out / f"{k}.mp3").exists()]
    print(f"{len(keys)} {lang} lines, {len(todo)} to record with {voice} at pitch {pitch}")
    for n, (k, line) in enumerate(todo, 1):
        record(line.removeprefix("es:").removeprefix("dora:"), voice, float(pitch), out / f"{k}.mp3", lang)
        if n % 100 == 0:
            print(f"{n} recorded")
print("Done")
