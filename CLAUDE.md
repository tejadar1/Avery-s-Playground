# Avery's Playground

SwiftUI iPhone/iPad app for young kids. See README.md for building.

- Code changes follow the `ponytail` plugin (enabled in `.claude/settings.json`): smallest complete change, reuse what's here.
- Writing (README, in-app text, commit messages, replies) follows the `no-ai-slop` skill (`.claude/skills/no-ai-slop`).
- Art style ("mixed"): thin dark-brown outlines (`Color.outline`), soft colors with a darker second tone for shading, small dot eyes, gentle drop shadows. Coco the crocodile is the mascot.
- Coco's personality is silly: goofy jokes, wordplay and sound effects ("Snap snap!", "Holy guacamole!"), always kind, never teasing the child.
- Illustrations live as SVG sources in `Art/` and are rendered to PNGs in the asset catalog with `Art/render.js`.
- Every push builds and runs the unit tests on one iPhone. `AverysPlaygroundUITests/ScreenshotTests.swift` (iPhone and iPad screenshots) and the TestFlight upload run only on main or a manual run (Actions → Build → Run workflow), to save Mac build minutes. New games get a step in the screenshot test, and every tap goes through its `tap()`/`find()` helpers, which wait for and scroll to the element. Check the build passes after pushing; the log prints the failure message if not.
