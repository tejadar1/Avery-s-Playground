# Avery's Playground

SwiftUI iPhone/iPad app for young kids. See README.md for building.

- Code changes follow the `ponytail` plugin (enabled in `.claude/settings.json`): smallest complete change, reuse what's here.
- Writing (README, in-app text, commit messages, replies) follows the `no-ai-slop` skill (`.claude/skills/no-ai-slop`).
- Art style: bright, flat cartoon colors with thick dark-brown outlines (`Color.outline`). Coco the crocodile is the mascot.
- Coco's personality is silly: goofy jokes, wordplay and sound effects ("Snap snap!", "Holy guacamole!"), always kind, never teasing the child.
- Illustrations live as SVG sources in `Art/` and are rendered to PNGs in the asset catalog with `Art/render.js`.
- Every push runs `AverysPlaygroundUITests/ScreenshotTests.swift` on an iPhone and an iPad. New games get a step there, and every tap goes through its `tap()`/`find()` helpers, which wait for and scroll to the element. Check the build passes after pushing; the log prints the failure message if not.
