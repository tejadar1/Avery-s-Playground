# Avery's Playground

A colorful, offline iPhone and iPad app for little kids (about ages 2–6), built with SwiftUI. Coco, a silly crocodile, hosts every game. Tap her for a joke.

## Games

| | Game | What happens |
|---|---|---|
| 💅 | **Nail Salon** | Tap a nail to zoom in, then paint it with a brush by dragging a finger. Add dots, stripes, hearts or stars, stick on a flower or a gem, then tap Done to show off. Coco cheers you on. |
| 💇 | **Hair Salon** | Shampoo, rinse, blow dry, comb and cut a girl's hair by dragging each tool over it. Then pick a style (ponytail, pigtails, space buns, afro puff, curly), a hair color and a bow. |
| 🐶 | **Mochi** | Take care of Mochi, a Shiba Inu puppy. Feed her, rub her to pet her (hearts float up), play fetch, scrub her in the bath, and put her down for a nap. Her food, love, energy and clean meters slowly drop while the app is closed, like a Tamagotchi, but never to zero. |
| 📖 | **Read** | A shelf of storybooks: The Three Little Pigs, Goldilocks, The Tortoise and the Hare, and The Little Red Hen. Slide a finger under the words and each word is read aloud as the finger reaches it, so she can follow along word by word; the last word stays lit. Tap the picture to hear the whole page. The shelf also has Sound it out: tap each letter of a word like "cat" to hear its sound, then pick the matching picture. |
| 🗣️ | **Español** | Spanish words and phrases in six sets: greetings, Dominican family sayings ("Bendición, mami"), animals, colors, numbers, and food. Tap a card to hear the Spanish, the English, then the Spanish again so your child can say it back. |
| 🔤 | **ABC** | Tap a letter to see and hear it: "A. A is for Apple!" |
| 🔢 | **1 2 3** | Pick a number, then tap each item to count out loud. |
| 🎨 | **Coloring** | A coloring book: a flower, a house, a fish, an ice cream cone and a butterfly. Pick a crayon (Coco says its name) and tap part of the picture to color it in. |
| 🐮 | **Animals** | Tap an animal to hear what it says: "The cow says moo!" |
| 🖍️ | **Draw** | Draw with your finger in lines that look like real crayon, with a waxy edge and paper showing through. Twelve soft crayon colors down the side (Coco names each one), plus undo and clear. |
| 🫧 | **Bubbles** | Pop floating bubbles; it cheers every 10 pops. |

## Notes for parents

- **No ads, no in-app purchases, no accounts, no internet.** Nothing is collected or sent anywhere.
- Words are read aloud with the iPhone's built-in voice, so no recordings are needed. Speech still plays
  when the silent switch is on.
- Big buttons, haptic "taps", and no text you need to read to get around.
- Tip: turn on **Guided Access** (Settings → Accessibility → Guided Access) to keep your child inside the app.

## Building and running

You need a Mac with **Xcode 16 or newer**. The app runs on iOS 17 or newer.

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen            # creates AverysPlayground.xcodeproj
open AverysPlayground.xcodeproj
```

Then in Xcode:

1. Select the **AverysPlayground** target → **Signing & Capabilities** → choose your **Team**
   (a free Apple ID works for running on your own phone).
2. The bundle ID is `com.tejadar1.averysplayground`. If Xcode says it's taken, change it in `project.yml`.
3. Plug in the iPhone (or pick a simulator) and press **Run** (⌘R).

## TestFlight (no Mac needed)

GitHub builds the app on every push (`.github/workflows/build.yml`). The **test** job compiles it and runs the
unit tests on an iPhone simulator. The **testflight** job uploads a build to TestFlight once these one-time
steps are done. Everything works in Safari on an iPhone.

1. Join the [Apple Developer Program](https://developer.apple.com/programs/) ($99/year).
2. On [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list), add an
   **Identifier** → App IDs → App, with the explicit bundle ID `com.tejadar1.averysplayground`.
3. In [App Store Connect](https://appstoreconnect.apple.com/apps), tap **+ New App**: iOS, pick that bundle ID,
   any SKU. The name must be unused on the App Store, so "Avery's Playground" may need a twist.
4. In App Store Connect → Users and Access → Integrations → **App Store Connect API**, generate a team key
   with **Admin** access. Note the Key ID and Issuer ID, and download the `.p8` file (Apple lets you download
   it only once).
5. Find your **Team ID** under Membership details on [developer.apple.com/account](https://developer.apple.com/account).
6. In this GitHub repo → Settings → Secrets and variables → Actions, add four repository secrets:
   - `APP_STORE_CONNECT_KEY_ID`: the Key ID
   - `APP_STORE_CONNECT_ISSUER_ID`: the Issuer ID
   - `APP_STORE_CONNECT_KEY`: the full text of the `.p8` file, including the BEGIN and END lines
   - `APPLE_TEAM_ID`: the Team ID
7. In GitHub → Actions → Build → **Run workflow**. When it finishes, Apple takes 10–30 minutes to process the
   build. Then in App Store Connect → your app → TestFlight → Internal Testing, add yourself as a tester and
   install it with the [TestFlight](https://apps.apple.com/app/testflight/id899247664) app.

After that, every push uploads a new build, and TestFlight offers the update.

## Project layout

```
AverysPlayground/
  App/          App entry point, home screen, list of games
  Activities/   One SwiftUI view per game
  Support/      Speech, haptics, fonts and shared styles
  Assets.xcassets
AverysPlaygroundTests/    Unit tests (run with ⌘U)
AverysPlaygroundUITests/  Opens every game and saves screenshots to the `screenshots` branch on each build
Art/            SVG sources for Coco, the hand, the game icons (Art/icons), and the app icon
project.yml     XcodeGen project definition
```

### Art

The art is flat, bright cartoon color with a thick dark-brown outline (`Color.outline` in code).
Coco and the hand are SVGs in `Art/`. After editing one, re-render the PNGs into the asset catalog:

```sh
node Art/render.js   # needs Playwright with Chromium
```

The nail positions in `NailSalonView.spots` must match the guide nails in `Art/hand.svg`.

### Building with Claude Code

Two tools from GitHub are part of how this app gets built. Claude Code loads both when it opens this repo:

- [ponytail](https://github.com/DietrichGebert/ponytail) keeps code changes small: reuse what's in the
  project, skip features nobody asked for, and add a test for new logic. It's a plugin, turned on in
  `.claude/settings.json`; Claude Code offers to install it the first time you trust the folder. Switch
  levels with `/ponytail lite`, `/ponytail ultra`, or turn it off with `stop ponytail`.
- [no-ai-slop](https://github.com/petergyang/no-ai-slop) keeps writing plain: the README, text kids see
  in the app, and commit messages. It has no Claude Code plugin, so a copy of the skill lives in
  `.claude/skills/no-ai-slop` (MIT licensed). Run it on any text with `/no-ai-slop`.

To get both on your own machine for every project, run these in Claude Code:

```
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```

and in a terminal: `npx skills add petergyang/no-ai-slop --skill no-ai-slop --global --yes`.

### Adding a new game

1. Create a view in `AverysPlayground/Activities/`.
2. Add a case to `Activity` in `App/Activity.swift` with a title, color, and destination.
3. Draw its icon as `Art/icons/<case name>.svg` and run `node Art/render.js`.

It shows up on the home screen automatically.
