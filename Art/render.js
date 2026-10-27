// Renders the SVGs in this folder into the app's asset catalog.
// Run from the repo root: node Art/render.js
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const assets = path.join(__dirname, '../AverysPlayground/Assets.xcassets');
// name in the asset catalog → [svg file, pixel width, parts to hide, scale]; game icons are named Icon-<Activity rawValue>.
const images = {
  Coco: ['coco.svg', 1200],
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
// The pictures in the games (Bingo tiles, ABC, stories...) are named Picture-<file name>.
for (const file of fs.readdirSync(path.join(__dirname, 'pictures'))) {
  images[`Picture-${path.basename(file, '.svg')}`] = [`pictures/${file}`, 400];
}
images['Picture-crocodile'] = ['coco.svg', 400];
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

  // Coco on top of a background SVG, at a box in its pixels.
  const coco = fs.readFileSync(path.join(__dirname, 'coco.svg'), 'utf8');
  async function compose(background, width, height, [x, y, w, h], file) {
    const scene = fs.readFileSync(path.join(__dirname, background), 'utf8');
    const page = await browser.newPage({ viewport: { width, height } });
    await page.setContent(`<style>${font}html,body{margin:0;background:transparent}div{position:absolute}svg{display:block;width:100%;height:100%}</style>`
      + `<div style="inset:0">${scene}</div><div style="left:${x}px;top:${y}px;width:${w}px;height:${h}px">${coco}</div>`, { waitUntil: 'networkidle' });
    await page.screenshot({ path: file, omitBackground: true });
    await page.close();
  }
  // Coco's box in the launch scene, in its 600×780 pixels: 30, 50, 140×146.67 points in GettingReady.
  await compose('launch-scene.svg', 600, 780, [90, 150, 420, 440], path.join(assets, 'LaunchCoco.imageset/LaunchCoco.png'));
  fs.writeFileSync(path.join(assets, 'LaunchCoco.imageset/Contents.json'), JSON.stringify({
    images: [{ filename: 'LaunchCoco.png', idiom: 'universal', scale: '3x' }],
    info: { author: 'xcode', version: 1 },
  }, null, 2) + '\n');
  // App icon: Coco on a hill in front of a sunburst, opaque, 1024×1024.
  await compose('icon-background.svg', 1024, 1024, [150, 110, 760, 796], path.join(assets, 'AppIcon.appiconset/AppIcon.png'));
  await browser.close();
})();
