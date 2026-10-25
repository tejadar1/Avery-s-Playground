# Avery's Playground

A colorful, offline iPhone and iPad app for little kids (about ages 2–6), built with SwiftUI. Coco the crocodile hosts.

## Games

| | Game | What happens |
|---|---|---|
| 💅 | **Nail Salon** | Paint each nail, add dots, stripes, hearts or stars, stick on a flower or a gem, then tap Done to show off. Coco cheers you on. |
| 🔤 | **ABC** | Tap a letter to see and hear it: "A. A is for Apple!" |
| 🔢 | **1 2 3** | Pick a number, then tap each item to count out loud. |
| 🎨 | **Colors** | Tap a color and the whole screen turns that color while it's named aloud. |
| 🐮 | **Animals** | Tap an animal to hear what it says: "The cow says moo!" |
| 🖍️ | **Draw** | Finger painting with crayons, three brush sizes, an eraser, undo, and clear. |
| 🫧 | **Bubbles** | Pop floating bubbles; it cheers every 10 pops. |

## Notes for parents

- **No ads, no in-app purchases, no accounts, no internet.** Nothing is collected or sent anywhere.
- Words are read aloud with the iPhone's built-in voice, so no recordings are needed. Speech still plays
  when the silent switch is on.
- Big buttons, haptic "taps", and no text you need to read to get around.
- Tip: turn on **Guided Access** (Settings → Accessibility → Guided Access) to keep your child inside the app.

## Building and running

You need a Mac with **Xcode 15 or newer**. The app runs on iOS 17 or newer.

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen            # creates AverysPlayground.xcodeproj
open AverysPlayground.xcodeproj
```

Then in Xcode:

1. Select the **AverysPlayground** target → **Signing & Capabilities** → choose your **Team**
   (a free Apple ID works for running on your own phone).
2. If Xcode complains about the bundle ID, change `com.example.averysplayground` to something unique,
   like `com.yourname.averysplayground`.
3. Plug in the iPhone (or pick a simulator) and press **Run** (⌘R).

## Project layout

```
AverysPlayground/
  App/          App entry point, home screen, list of games
  Activities/   One SwiftUI view per game
  Support/      Speech, haptics, fonts and shared styles
  Assets.xcassets
AverysPlaygroundTests/  Unit tests (run with ⌘U)
Art/            SVG sources for Coco, the hand, and the app icon
project.yml     XcodeGen project definition
```

### Art

The art is flat, bright cartoon color with a thick dark-brown outline (`Color.outline` in code).
Coco and the hand are SVGs in `Art/`. After editing one, re-render the PNGs into the asset catalog:

```sh
node Art/render.js   # needs Playwright with Chromium
```

The nail positions in `NailSalonView.spots` must match the guide nails in `Art/hand.svg`.

### Agent skills

`.claude/skills/` holds two skills that Claude Code picks up automatically in this repo:
[ponytail](https://github.com/DietrichGebert/ponytail) (write the smallest change that fully works) and
[no-ai-slop](https://github.com/petergyang/no-ai-slop) (plain writing). Both are MIT licensed.

### Adding a new game

1. Create a view in `AverysPlayground/Activities/`.
2. Add a case to `Activity` in `App/Activity.swift` with a title, emoji, color, and destination.

It shows up on the home screen automatically.
