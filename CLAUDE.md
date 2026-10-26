# Avery's Playground

SwiftUI iPhone/iPad app for young kids. See README.md for building.

- Code changes follow the `ponytail` plugin (enabled in `.claude/settings.json`): smallest complete change, reuse what's here.
- Writing (README, in-app text, commit messages, replies) follows the `no-ai-slop` skill (`.claude/skills/no-ai-slop`).
- Art style ("mixed"): thin dark-brown outlines (`Color.outline`), soft colors with a darker second tone for shading, small dot eyes, gentle drop shadows. Coco the crocodile is the mascot.
- Coco's personality is silly: goofy jokes, wordplay and sound effects ("Snap snap!", "Holy guacamole!"), always kind, never teasing the child.
- Illustrations live as SVG sources in `Art/` and are rendered to PNGs in the asset catalog with `Art/render.js`.
- Builds cost Mac minutes, so nothing builds on push or merge. Batch changes, then start one build by hand (`run_workflow` on build.yml for the branch): it runs the unit tests on one iPhone and uploads to TestFlight. Tick `screenshots` only when there's something new to look at; it runs `AverysPlaygroundUITests/ScreenshotTests.swift` on iPhone and iPad. New games get a step in the screenshot test, and every tap goes through its `tap()`/`find()` helpers, which wait for and scroll to the element. Check the build passes after starting it; the log prints the failure message if not.
- Coco's voice is recorded (README → Coco's voice). After adding or changing a line Coco says, run `python3 Voice/lines.py > Voice/lines.txt` and a build with `voice: record` before the next app build, or the new line falls back to the iPad's voice.
