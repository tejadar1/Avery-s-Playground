// Renders the SVGs in this folder into the app's asset catalog.
// Run from the repo root: node Art/render.js
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const assets = path.join(__dirname, '../AverysPlayground/Assets.xcassets');
// name in the asset catalog → [svg file, pixel width, parts to hide, scale]; game icons are named Icon-<Activity rawValue>.
const images = {
  Coco: ['coco.svg', 1200],
  Avery: ['avery.svg', 900],
  // The launch screen shows images at their natural size, 3x: 600px is 200 points. LaunchCoco (Coco on her
  // scene) is made below; GettingReady shows LaunchScene with Coco on top in the same spot, so she can move.
  LaunchScene: ['launch-scene.svg', 600, 'none', '3x'],
  'Icon-pet': ['shiba.svg', 600, '#sleep'],
  MochiRoom: ['mochi-room.svg', 2400],
};
// Mochi from the side: one image per part, all the same size, stacked in PetView so the parts can move.
const mochiParts = ['legFarBack', 'legFarFront', 'tail', 'body', 'legBack', 'legFront', 'head', 'headSleep'];
for (const part of mochiParts) {
  const name = 'Mochi' + part[0].toUpperCase() + part.slice(1);
  images[name] = ['mochi.svg', 600, mochiParts.filter((p) => p !== part).map((p) => '#' + p).join(', ')];
}
for (const file of fs.readdirSync(path.join(__dirname, 'icons'))) {
  images[`Icon-${path.basename(file, '.svg')}`] = [`icons/${file}`, 600];
}
// One image per layer: the Dress Up doll and the hair salon customer's face (doll.js writes both), and Spot It's rooms (spot.js).
for (const [prefix, file, width] of [['Doll', 'doll.svg', 1000], ['Salon', 'salon.svg', 800], ['Spot-living', 'spot-living.svg', 1200], ['Spot-bedroom', 'spot-bedroom.svg', 1200], ['Spot-park', 'spot-park.svg', 1200], ['Spot-school', 'spot-school.svg', 1200]]) {
  const svg = fs.readFileSync(path.join(__dirname, file), 'utf8');
  const parts = [...svg.matchAll(/<g id="([\w-]+)" class="part">/g)].map((m) => m[1]);
  for (const part of parts) {
    images[`${prefix}-${part}`] = [file, width, parts.filter((p) => p !== part).map((p) => '#' + p).join(', ')];
  }
}
// The pictures in the games (Bingo tiles, ABC, stories...) are named Picture-<file name>.
for (const file of fs.readdirSync(path.join(__dirname, 'pictures'))) {
  images[`Picture-${path.basename(file, '.svg')}`] = [`pictures/${file}`, 400];
}
// The Puzzles pictures (Art/puzzles.js writes them) are named Puzzle-<file name>.
for (const file of fs.readdirSync(path.join(__dirname, 'puzzles'))) {
  images[`Puzzle-${path.basename(file, '.svg')}`] = [`puzzles/${file}`, 1200];
}
images['Picture-crocodile'] = ['coco.svg', 400];
images['Picture-avery'] = ['avery.svg', 400];
const font = "@import url('https://fonts.googleapis.com/css2?family=Nunito:wght@900&display=swap');text{font-family:Nunito;font-weight:900}";

(async () => {
  const browser = await chromium.launch();
  for (const [name, [file, pixelWidth, hide = 'none', scale]] of Object.entries(images)) {
    const svg = fs.readFileSync(path.join(__dirname, file), 'utf8');
    const [, , vw, vh] = svg.match(/viewBox="([^"]+)"/)[1].split(/\s+/).map(Number);
    const height = Math.round(pixelWidth * vh / vw);
    const page = await browser.newPage({ viewport: { width: pixelWidth, height } });
    await page.setContent(`<style>${font}html,body{margin:0}svg{display:block;width:100vw;height:100vh}${hide}{display:none}</style>${svg}`, { waitUntil: 'networkidle' });
    const dir = path.join(assets, `${name}.imageset`);
    fs.mkdirSync(dir, { recursive: true });
    await page.screenshot({ path: path.join(dir, `${name}.png`), omitBackground: true });
    fs.writeFileSync(path.join(dir, 'Contents.json'), JSON.stringify({
      images: [{ filename: `${name}.png`, idiom: 'universal', ...(scale && { scale }) }],
      info: { author: 'xcode', version: 1 },
    }, null, 2) + '\n');
    await page.close();
  }

  // Coco (and anyone else in `others`: [svg, box]) on top of a background SVG, at a box in its pixels.
  const coco = fs.readFileSync(path.join(__dirname, 'coco.svg'), 'utf8');
  const box = (svg, [x, y, w, h]) => `<div style="left:${x}px;top:${y}px;width:${w}px;height:${h}px">${svg}</div>`;
  async function compose(background, width, height, cocoBox, file, others = []) {
    const scene = fs.readFileSync(path.join(__dirname, background), 'utf8');
    const page = await browser.newPage({ viewport: { width, height } });
    await page.setContent(`<style>${font}html,body{margin:0;background:transparent}div{position:absolute}svg{display:block;width:100%;height:100%}</style>`
      + `<div style="inset:0">${scene}</div>${box(coco, cocoBox)}${others.map(([svg, b]) => box(svg, b)).join('')}`, { waitUntil: 'networkidle' });
    await page.screenshot({ path: file, omitBackground: true });
    await page.close();
  }
  // Coco's box in the launch scene, in its 600×780 pixels: 30, 50, 140×146.67 points in GettingReady.
  await compose('launch-scene.svg', 600, 780, [90, 150, 420, 440], path.join(assets, 'LaunchCoco.imageset/LaunchCoco.png'));
  fs.writeFileSync(path.join(assets, 'LaunchCoco.imageset/Contents.json'), JSON.stringify({
    images: [{ filename: 'LaunchCoco.png', idiom: 'universal', scale: '3x' }],
    info: { author: 'xcode', version: 1 },
  }, null, 2) + '\n');
  // App icon: Coco and Avery waving on a hill in front of a sunburst, opaque, 1024×1024.
  const avery = fs.readFileSync(path.join(__dirname, 'avery.svg'), 'utf8');
  await compose('icon-background.svg', 1024, 1024, [40, 200, 560, 586], path.join(assets, 'AppIcon.appiconset/AppIcon.png'),
    [[avery, [470, 250, 520, 572]]]);
  await browser.close();
})();
