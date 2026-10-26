# Avery's World

A colorful, offline iPhone and iPad app for little kids (about ages 2–6), built with SwiftUI. Coco, a silly crocodile, hosts every game. Tap her for a joke.

## Games

The home screen has three big choices: **Learn** (Read, Math, Español, ABC, 1 2 3, Piano), **Play** (Nail Salon,
Hair Salon, Dress Up, Mochi, Coloring, Draw) and **Team Up**, games to play with a grown-up (Bingo, Tic-Tac-Toe).

| | Game | What happens |
|---|---|---|
| 💅 | **Nail Salon** | A big open hand with natural nails. Tap a nail to zoom in, then paint it with a brush by dragging a finger; brushing a new color over another blends them. Polish comes in plain colors and fine glitter, some fading from one color into another. Add dots, stripes, hearts or stars, stick on a flower or a gem, then tap Done to show off. A "Copy this!" card shows a look to try (tap it for another), and a button changes the skin tone. |
| 💇 | **Hair Salon** | Shampoo, rinse, blow dry, comb and cut a girl's hair by dragging each tool over it. Then pick a style (ponytail, pigtails, space buns, afro puff, curly), a hair color and a bow. |
| 👗 | **Dress Up** | Dress a fashion doll with long hair and long legs: a sparkly gown, party dress, tutu, t-shirt, overalls or pajamas in any color (hot pink first), plus high heels or other shoes, a hat, and a purse, wand, sunglasses or necklace. Tap Done for a fashion show. |
| 🐶 | **Mochi** | Mochi, a Shiba Inu puppy, trots around her living room. Throw her ball and she runs to fetch it; put down her bowl and she walks over and eats; spray her clean with the hose (the mud fades, then she shakes off); tap Sleep and she curls up in her bed; rub her for hearts. Her food, love, energy and clean meters slowly drop while the app is closed, like a Tamagotchi, but never to zero. |
| 🎹 | **Piano** | A rainbow keyboard. Pick Twinkle Twinkle, Mary Had a Little Lamb or Hot Cross Buns and a bouncing star shows the next key while the words light up, or play freely. Slide a finger across the keys to glide up and down. |
| 📖 | **Read** | A shelf of storybooks: The Three Little Pigs, Goldilocks, The Tortoise and the Hare, and The Little Red Hen. Slide a finger under the words and each word is read aloud as the finger reaches it, so she can follow along word by word; the last word stays lit. Tap the picture to hear the whole page. A Spanish shelf, Cuentos en español, has La Cucarachita Martina, Juan Bobo y la puerca and La Ciguapa del bosque, read word by word in a Spanish voice. The shelf also has Sound it out: tap each letter of a word like "cat" to hear its sound, then pick the matching picture. |
| 🍕 | **Math** | Adding with food: "Coco has 2 slices of pizza. Mochi brings 1 more. How many now?" Tap the slices to count them, then pick the answer. Sums up to 10. |
| 🗣️ | **Español** | Spanish words and phrases in six sets: greetings, Dominican family sayings ("Bendición, mami"), animals, colors, numbers, and food. Tap a card to hear the Spanish, the English, then the Spanish again so your child can say it back. |
| 🔤 | **ABC** | Tap a letter to see and hear it: "A. A is for Apple!" |
| 🔢 | **1 2 3** | Pick a number, then tap each item to count out loud. |
| 🎨 | **Coloring** | A coloring book: a flower, a house, a fish, an ice cream cone and a butterfly. Pick a crayon (Coco says its name) and tap part of the picture to color it in. |
| 🖍️ | **Draw** | Draw with your finger in lines that look like real crayon, with a waxy edge and paper showing through. Twelve soft crayon colors down the side (Coco names each one), plus undo and clear. |
| 🎲 | **Bingo** | Picture bingo for a kid and a grown-up together, against Coco, like Zingo: slide out two tiles (Coco reads their words), tap one that's on your card to cover it, and fill your card before Coco does. Coco is a little slow, on purpose. |
| ⭐️ | **Tic-Tac-Toe** | For a kid and a grown-up on one iPad: stars against hearts, three in a row wins. The winning row lights up and each side's wins are counted. |

## Notes for parents

- **No ads, no in-app purchases, no accounts, no internet.** Nothing is collected or sent anywhere.
- Words are read aloud with the iPhone's built-in voice, so no recordings are needed. Speech still plays
  when the silent switch is on.
- For a more natural voice, download a Premium or Enhanced one: Settings → Accessibility → Spoken Content →
  Voices → English (and Spanish for the Spanish games). The app uses the best voice it finds.
- Big buttons, haptic "taps", and no text you need to read to get around.
- Follows Apple's design guidelines for kids' apps: buttons at least 44 points, standard back navigation, and
  Reduce Motion (Settings → Accessibility → Motion) stills the wagging, twinkling and spinning.
- The app opens with Coco getting ready (about 2 seconds; tap to skip).
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

GitHub builds the app on a Mac (`.github/workflows/build.yml`), which is costly on a private repo, so it only
builds when started by hand: Actions → Build → **Run workflow**. Each run tests the app on an iPhone simulator and
uploads it to TestFlight. Screenshots of every game on iPhone and iPad take about 10 more minutes, so they only
run when you tick **Take screenshots**. The upload
needs these one-time steps, all doable in Safari on an iPhone.

1. Join the [Apple Developer Program](https://developer.apple.com/programs/) ($99/year).
2. On [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list), add an
   **Identifier** → App IDs → App, with the explicit bundle ID `com.tejadar1.averysplayground`.
3. In [App Store Connect](https://appstoreconnect.apple.com/apps), tap **+ New App**: iOS, pick that bundle ID,
   any SKU. The name must be unused on the App Store, so use something like "Avery's World: Kids Games".
   The name under the icon is "Avery's World" either way (set in `project.yml`).
4. In App Store Connect → Users and Access → Integrations → **App Store Connect API**, generate a team key
   with **Admin** access and download the `.p8` file (Apple lets you download it only once).
5. Put the key's Key ID, the Issuer ID and your Team ID (Membership details on
   [developer.apple.com/account](https://developer.apple.com/account)) in the `testflight` job in
   `.github/workflows/build.yml`. They aren't secret.
6. In this GitHub repo → Settings → Secrets and variables → Actions, add one repository secret,
   `APP_STORE_CONNECT_KEY`: the full text of the `.p8` file, including the BEGIN and END lines.
7. In GitHub → Actions → Build → **Run workflow**. When it finishes, Apple takes 10–30 minutes to process the
   build. Then in App Store Connect → your app → TestFlight → Internal Testing, add yourself as a tester and
   install it with the [TestFlight](https://apps.apple.com/app/testflight/id899247664) app.

After that, each run uploads a new build, and TestFlight offers the update.

## Project layout

```
AverysPlayground/
  App/          App entry point, home screen, list of games
  Activities/   One SwiftUI view per game
  Support/      Speech, haptics, fonts and shared styles
  Assets.xcassets
AverysPlaygroundTests/    Unit tests (run with ⌘U)
AverysPlaygroundUITests/  Opens every game and saves screenshots to the `screenshots` branch (manual builds with screenshots ticked)
Art/            SVG sources for Coco, Mochi, the game icons (Art/icons), the pictures in the games (Art/pictures), and the app icon
project.yml     XcodeGen project definition
```

### Art

The art is soft cartoon color with a thin dark-brown outline (`Color.outline` in code), a darker second tone for shading, and small dot eyes.
Coco and Mochi are SVGs in `Art/` (Mochi's room is `mochi-room.svg`, and `mochi.svg` holds her side view in parts that move). The pictures in the games (Bingo tiles, ABC, stories and so on) are in `Art/pictures`, and the code shows one with `Picture("cat", size:)`; the app uses no emoji. After editing an SVG, re-render the PNGs into the asset catalog:

```sh
node Art/render.js   # needs Playwright with Chromium
```

The Nail Salon hand is drawn in code (`Hand` in `NailSalonView.swift`) so its skin tone can change.

### Coco's voice

Coco's English lines are recorded with [Kokoro](https://github.com/hexgrad/kokoro), a free open-source voice, with the
pitch raised for a cartoon sound, so she doesn't sound like the iPad's built-in voice. `Voice/lines.txt` lists every
line (made by `python3 Voice/lines.py > Voice/lines.txt`) and `Voice/voice.txt` names the voice and pitch. Run
Actions → Build → Run workflow with **voice: record** to record new lines into `AverysPlayground/Voice/` (free, on
Linux), or **voice: samples** to hear several voices on the `voice-samples` branch. Lines without a recording, and
Spanish, use the iPad's voice.

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
