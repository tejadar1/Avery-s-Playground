"""Lists every line Coco can say, one per line, for Voice/make.py to record. Spanish lines start with "es:";
"book:" lines are Bella, who reads, names things and teaches (letters, numbers, words, colors); Coco does the silly cheering.

Run from the repo root after changing what Coco says: python3 Voice/lines.py > Voice/lines.txt
Plain strings are taken from the Swift source; lines built from data (numbers, names) are spelled out below.
Lines that don't get a recording, like hints shown only in Coco's bubble, cost a little but do no harm.
"""
import re
from pathlib import Path

app = Path(__file__).resolve().parent.parent / "AverysPlayground"
src = {p.name: p.read_text() for p in (app / "Activities").glob("*.swift")}
theme = (app / "Support" / "Theme.swift").read_text() + (app / "Support" / "Customers.swift").read_text()
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


# English books are read by the storyteller ("book:"); Coco only says a book's name when its cover is tapped.
lines |= story_lines(english["StoriesView.swift"], "book:")
lines.update({"book:The end!", "book:That's right!"})

# Spanish, in Coco's Spanish voice: the stories, the end, and the Spanish cards with their English meanings.
lines |= story_lines(src["StoriesView.swift"].split("static let spanish")[1], "es:")
lines.add("es:¡Colorín colorado, este cuento se ha acabado!")
spanish = src["SpanishView.swift"]
# English meanings are said in Bella's voice ("book:"), right after the Spanish
for es, en in re.findall(r'SpanishWord\(spanish: "([^"]+)", english: "([^"]+)"', spanish):
    if "\\(" not in es:  # "Me llamo \(Kid.name)" is below, with the child's name
        lines.update({"es:" + es, "book:" + en})
titles = dict(re.findall(r'case \.(\w+): "([^"]+)"', spanish.split("var title")[1].split("var english")[0]))
meanings = dict(re.findall(r'case \.(\w+): "([^"]+)"', spanish.split("var english")[1].split("var picture")[0]))
for case, title in titles.items():
    lines.update({"es:" + title, "book:" + meanings[case]})

# Letter tracing: the letter's name, said before a silly cheer when it's traced
lines.update(f"book:{letter}!" for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ")  # in Bella's voice

# Each letter's sound for Spell and Sound it out, recorded from its IPA ("sound:æ"); see make.py
lines.update("sound:" + ipa for ipa in re.findall(r'"\w": \("([^"]+)", "[^"]+"\)', src["ReadingView.swift"]))

numbers = range(1, 21)
lines.update(f"book:{n}" for n in numbers)  # counting, in Bella's voice
lines.update(f"Let's count to {n}!" for n in range(1, 11))

for letter, word, phrase in re.findall(r'Letter\(letter: "(\w)", word: "([^"]+)", picture: "[^"]+"(?:, phrase: "([^"]+)")?\)', src["ABCView.swift"]):
    lines.add("book:" + (phrase or f"{letter} is for {word}!"))  # in Bella's voice

for word in re.findall(r'ReadingWord\(text: "(\w+)"', src["ReadingView.swift"]):
    lines.update({f"book:{word}! You read it!", f"Hee hee, that's a {word}!", f"book:{word}! You spelled it!", "book:" + word})

# Rhyme Time: Coco asks, Bella says the answer
rhyme = src["RhymeView.swift"]
groups = [re.findall(r'text: "(\w+)"', g) for g in re.findall(r'\[(\.init\(text: [^\]]+)\]', rhyme.split("static let starts")[0])]
for group in groups:
    for a in group:
        lines.add(f"Which one rhymes with {a}?")
        lines.update(f"book:{a} and {b} rhyme!" for b in group if b != a)
for word in re.findall(r'text: "(\w+)"', rhyme):
    lines.update({f"Hee hee, that's a {word}!", f"book:{word}!"})

# What's Next?, Sort It and Feelings: Bella names the picture; the "Hee hee" lines name the wrong one
for word in re.findall(r'text: "(\w+)"', src["PatternView.swift"]):
    lines.update({f"book:{word}!", f"Hee hee, not the {word}!"})
for word in re.findall(r'"(\w+)"', src["SortView.swift"].split("static let all")[1].split("private static")[0]):
    lines.add("book:" + ("ice cream" if word == "icecream" else word) + "!")
for sort in re.findall(r'Basket\(name: "([^"]+)"[^\n]+\n\s+right: Basket\(name: "([^"]+)"', src["SortView.swift"]):
    lines.add(f"{sort[0].capitalize()} or {sort[1]}?")
for name, help in re.findall(r'Feeling\(name: "(\w+)", face: "[^"]+", help: "([^"]+)"', src["FeelingsView.swift"]):
    lines.update({f"Which one feels {name}?", f"Hee hee, that one feels {name}!", "book:" + help})

colors = src["ColorsView.swift"]
for page in re.findall(r'ColoringPage\(name: "([^"]+)"|^\s+name: "([^"]+)",', colors, re.M):
    name = page[0] or page[1]
    lines.update({f"A {name}!", f"Wowza! You colored the whole {name}!"})
for name, example in re.findall(r'NamedColor\(name: "([^"]+)", color: [^,]+, exampleName: "([^"]+)"\)', colors):
    lines.add(f"book:{name}! Like {example}.")

hair = src["HairSalonView.swift"]
styles = hair.split("enum HairStyle")[1].split("\nenum ")[0]
lines.update(f"{name}! So cute!" for name in re.findall(r'case \.\w+: "([^"]+)"', styles.split("var name")[1].split("}")[0]))

dress = src["DressUpView.swift"]
cheers = literals(re.search(r"static let cheers = \[([^\]]+)\]", dress).group(1))
items = [i for enum in re.findall(r"enum \w+: String, CaseIterable \{([^}]+)\}", dress) for i in re.findall(r'\w+ = "([^"]+)"', enum)]
for item in items:
    lines.update(f"{item}! {cheer}" for cheer in cheers)

for song in re.findall(r'name: "([^"]+)", picture:', src["PianoView.swift"]):
    lines.update({f"book:{song}!", f"You played {song}! Holy guacamole, what a song!"})

# Math's four kinds of problems (MathProblem): questions in Coco's voice, solutions in Bella's
for one, many in re.findall(r'Food\(picture: "[^"]+", one: "([^"]+)", many: "([^"]+)"\)', src["MathView.swift"]):
    count = lambda n: f"{n} {one if n == 1 else many}"
    for a in range(1, 6):
        for b in range(1, 6):
            lines.add(f"Coco has {count(a)}. Mochi brings {b} more. How many now?")
    lines.update(f"Who has {which} {many}, Coco or Mochi?" for which in ["more", "fewer"])
    for whole in range(2, 7):
        for part in range(1, whole):
            lines.add(f"Coco has {count(whole)}. {part} {'is' if part == 1 else 'are'} on the plate. How many are in the box?")
            lines.add(f"Coco has {count(whole)}. Mochi eats {part}. How many are left?")
for a in range(1, 6):
    for b in range(1, 6):
        lines.add(f"book:{a} plus {b} is {a + b}!")
for whole in range(2, 7):
    for part in range(1, whole):
        lines.update({f"book:{part} and {whole - part} make {whole}!", f"book:{whole} take away {part} is {whole - part}!"})
lines.update(f"book:{who} has {which}!" for who in ["Coco", "Mochi"] for which in ["more", "fewer"])
lines.update(f"Hee hee, not {n}!" for n in range(0, 11))

bingo = re.findall(r'BingoTile\(word: "([^"]+)"', src["BingoView.swift"])
for a in bingo:
    lines.update({f"book:{a}!", f"Hee hee, the {a} isn't on your card.", f"Snap! I need the {a}!", f"Hee hee, that's not the {a}!"})
    lines.update(f"{a} and {b}!" for b in bingo)

# Coco says hi to each customer by name: the friends at the salon and in dress up, and the dentist's animals
friends = re.findall(r'Friend\(name: "(\w+)"', (app / "Support" / "Customers.swift").read_text())
patients = re.findall(r'case \.(?:lion|bear|bunny|kitty): "(\w+)"', src["DentistView.swift"])
lines.update(f"Hi {name}!" for name in friends + patients + ["Avery"])

# The child's name (Kid.swift): lines with it are recorded for Avery, and also without it, for any other name
lines.update({"es:Me llamo Avery", "book:My name is Avery", "All done! Sweet dreams, Avery!", "Avery! You wrote your name!"})


def unnamed(line, name="Avery"):
    out = line.replace(f"Hi {name}!", "Hi!").replace(f", {name}!", "!").replace(f"{name}! ", "")
    return out if out != line else None


for line in [l for l in lines if "Avery" in l]:
    if unnamed(line):
        lines.add(unnamed(line))
tools = re.search(r'enum DentistTool.*?\n(.*?)\n', src["DentistView.swift"]).group(1)
lines.update(f"book:{name}!" for name in re.findall(r'= "(\w+)"', tools))

# Bella names things: the trays and tools in the salons and Dress Up, the crayons in Draw, and the stickers
for name in ["HairSalonView.swift", "NailSalonView.swift", "DressUpView.swift"]:
    for block in re.findall(r"var name: String \{(.*?)\n    \}", src[name], re.S):
        lines.update("book:" + n for n in re.findall(r'case \.\w+: "([^"]+)"', block))
lines.update("book:" + n for n in re.findall(r'\("(\w+)", (?:Color|\.white)', src["DrawingView.swift"]))
lines.update("book:" + n for n in literals(src["StickerBookView.swift"].split("static let all = [")[1].split("]")[0]))

print("\n".join(sorted(lines)))
