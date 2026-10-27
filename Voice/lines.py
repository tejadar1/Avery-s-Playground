"""Lists every line Coco can say, one per line, for Voice/make.py to record. Spanish lines start with "es:".

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


# Plain strings Coco might say in English. The Spanish ones are listed below.
english = {name: text for name, text in src.items() if name != "SpanishView.swift"}
english["StoriesView.swift"] = english["StoriesView.swift"].split("static let spanish")[0]
for text in list(english.values()) + [theme]:
    for s in literals(text):
        if "\\(" in s or not re.search(r"[A-Za-z]", s):
            continue
        if re.fullmatch(r"[a-z0-9]+(\.[a-z0-9]+)+|[a-z]{2}-[A-Z]{2}|(Icon|Picture)-.*", s):
            continue  # SF Symbol names, language codes, asset names
        lines.add(s)



def story_lines(stories, prefix=""):
    """Story titles, pages, and each word as the finger reaches it (with punctuation trimmed, as the app does)."""
    found = set(re.findall(r'title: "([^"]+)"', stories))
    for page in re.findall(r'text: "([^"]+)"', stories):
        found.add(page)
        found.update(w for w in (w.strip(".,!?;:'\"¿¡") for w in page.split(" ")) if w)
    return {prefix + line for line in found}


lines |= story_lines(english["StoriesView.swift"])

# Spanish, in Coco's Spanish voice: the stories, the end, and the Spanish cards with their English meanings.
lines |= story_lines(src["StoriesView.swift"].split("static let spanish")[1], "es:")
lines.add("es:¡Colorín colorado, este cuento se ha acabado!")
spanish = src["SpanishView.swift"]
for es, en in re.findall(r'SpanishWord\(spanish: "([^"]+)", english: "([^"]+)"', spanish):
    lines.update({"es:" + es, en})
titles = dict(re.findall(r'case \.(\w+): "([^"]+)"', spanish.split("var title")[1].split("var english")[0]))
meanings = dict(re.findall(r'case \.(\w+): "([^"]+)"', spanish.split("var english")[1].split("var picture")[0]))
for case, title in titles.items():
    lines.update({"es:" + title, meanings[case]})

# Letter tracing: the letter's name as it comes up, and a cheer when it's traced
for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
    lines.update({f"{letter}!", f"{letter}! Great tracing!"})

numbers = range(1, 21)
lines.update(str(n) for n in numbers)
lines.update(f"Let's count to {n}!" for n in range(1, 11))

for letter, word, phrase in re.findall(r'Letter\(letter: "(\w)", word: "([^"]+)", picture: "[^"]+"(?:, phrase: "([^"]+)")?\)', src["ABCView.swift"]):
    lines.add(phrase or f"{letter} is for {word}!")

for word in re.findall(r'ReadingWord\(text: "(\w+)"', src["ReadingView.swift"]):
    lines.update({f"{word}! You read it! Snap snap!", f"Hee hee, that's a {word}!", f"{word}! You spelled it!", word})

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

for song in re.findall(r'name: "([^"]+)", picture:', src["PianoView.swift"]):
    lines.update({f"{song}!", f"You played {song}! Holy guacamole, what a song!"})

for one, many in re.findall(r'Food\(picture: "[^"]+", one: "([^"]+)", many: "([^"]+)"\)', src["MathView.swift"]):
    for a in range(1, 6):
        for b in range(1, 6):
            lines.add(f"Coco has {a} {one if a == 1 else many}. Mochi brings {b} more. How many now?")
for a in range(1, 6):
    for b in range(1, 6):
        lines.add(f"{a} plus {b} is {a + b}! Yummy! Snap snap!")
lines.update(f"Hee hee, not {n}!" for n in range(1, 11))

bingo = re.findall(r'BingoTile\(word: "([^"]+)"', src["BingoView.swift"])
for a in bingo:
    lines.update({f"{a}!", f"{a}! You got it!", f"Hee hee, the {a} isn't on your card.", f"Snap! I need the {a}!"})
    lines.update(f"{a} and {b}!" for b in bingo)

print("\n".join(sorted(lines)))
