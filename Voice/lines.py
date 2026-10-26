"""Lists every English line Coco can say, one per line, for Voice/make.py to record.

Run from the repo root after changing what Coco says: python3 Voice/lines.py > Voice/lines.txt
Plain strings are taken from the Swift source; lines built from data (numbers, names) are spelled out below.
Lines that don't get a recording, like hints shown only in Coco's bubble, cost a little but do no harm.
"""
import re
from pathlib import Path

app = Path(__file__).resolve().parent.parent / "AverysPlayground"
src = {p.name: p.read_text() for p in (app / "Activities").glob("*.swift")}
theme = (app / "Support" / "Theme.swift").read_text()
lines = set()


def literals(text):
    return re.findall(r'"((?:[^"\\]|\\.)*)"', text)


# Plain strings Coco might say. Spanish is spoken by the iPad's Spanish voice, so skip it.
english = {name: text for name, text in src.items() if name != "SpanishView.swift"}
english["StoriesView.swift"] = english["StoriesView.swift"].split("static let spanish")[0]
for text in list(english.values()) + [theme]:
    for s in literals(text):
        if "\\(" in s or not re.search(r"[A-Za-z]", s):
            continue
        if re.fullmatch(r"[a-z0-9]+(\.[a-z0-9]+)+|[a-z]{2}-[A-Z]{2}|Icon-.*", s):
            continue  # SF Symbol names, language codes, asset names
        lines.add(s)

# Story words, as the finger reaches each one
stories = english["StoriesView.swift"]
for page in re.findall(r'text: "([^"]+)"', stories):
    for word in page.split(" "):
        word = word.strip(".,!?;:'\"")
        if word:
            lines.add(word)

numbers = range(1, 21)
lines.update(str(n) for n in numbers)
lines.update(f"{n}! Great counting!" for n in range(1, 11))
lines.update(f"Let's count to {n}!" for n in range(1, 11))
lines.update(f"{n} bubbles! Wow!" for n in range(10, 310, 10))

for letter, word, phrase in re.findall(r'Letter\(letter: "(\w)", word: "([^"]+)", emoji: "[^"]+"(?:, phrase: "([^"]+)")?\)', src["ABCView.swift"]):
    lines.add(f"{letter}. " + (phrase or f"{letter} is for {word}!"))

for word in re.findall(r'ReadingWord\(text: "(\w+)"', src["ReadingView.swift"]):
    lines.update({f"{word}! You read it! Snap snap!", f"Hee hee, that's a {word}!"})

colors = src["ColorsView.swift"]
for page in re.findall(r'ColoringPage\(name: "([^"]+)"|^\s+name: "([^"]+)",', colors, re.M):
    name = page[0] or page[1]
    lines.update({f"A {name}!", f"Wowza! You colored the whole {name}!"})
for name, example in re.findall(r'NamedColor\(name: "([^"]+)", color: [^,]+, exampleName: "([^"]+)"\)', colors):
    lines.add(f"{name}! Like {example}.")

hair = src["HairSalonView.swift"]
styles = hair.split("enum HairStyle")[1].split("\nenum ")[0]
lines.update(f"{name}! So cute!" for name in re.findall(r'case \.\w+: "([^"]+)"', styles.split("var name")[1].split("}")[0]))

dress = src["DressUpView.swift"]
cheers = literals(re.search(r"static let cheers = \[([^\]]+)\]", dress).group(1))
for item in re.findall(r'case \w+ = "([^"]+)"', dress):
    lines.update(f"{item}! {cheer}" for cheer in cheers)

for song in re.findall(r'name: "([^"]+)", emoji:', src["PianoView.swift"]):
    lines.update({f"{song}!", f"You played {song}! Holy guacamole, what a song!"})

for one, many in re.findall(r'Food\(emoji: "[^"]+", one: "([^"]+)", many: "([^"]+)"\)', src["MathView.swift"]):
    for a in range(1, 6):
        for b in range(1, 6):
            lines.add(f"Coco has {a} {one if a == 1 else many}. Mochi brings {b} more. How many now?")
for a in range(1, 6):
    for b in range(1, 6):
        lines.add(f"{a} plus {b} is {a + b}! Yummy! Snap snap!")
lines.update(f"Hee hee, not {n}!" for n in range(1, 11))

print("\n".join(sorted(lines)))
