// Renders the SVGs in this folder into the app's asset catalog.
// Run from the repo root: node Art/render.js
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const assets = path.join(__dirname, '../AverysPlayground/Assets.xcassets');
// name in the asset catalog → [svg file, pixel width, parts to hide]; game icons are named Icon-<Activity rawValue>.
const images = {
  Coco: ['coco.svg', 1200],
  Hand: ['hand.svg', 1200, '#nails'],
  Shiba: ['shiba.svg', 900, '#tail, #sleep'],
  ShibaSleep: ['shiba.svg', 900, '#tail, #awake'],
  ShibaTail: ['shiba.svg', 900, '#body'],
  'Icon-pet': ['shiba.svg', 600, '#sleep'],
};
for (const file of fs.readdirSync(path.join(__dirname, 'icons'))) {
  images[`Icon-${path.basename(file, '.svg')}`] = [`icons/${file}`, 600];
}
const font = "@import url('https://fonts.googleapis.com/css2?family=Nunito:wght@900&display=swap');text{font-family:Nunito;font-weight:900}";

(async () => {
  const browser = await chromium.launch();
  for (const [name, [file, pixelWidth, hide = 'none']] of Object.entries(images)) {
    const svg = fs.readFileSync(path.join(__dirname, file), 'utf8');
    const [, , vw, vh] = svg.match(/viewBox="([^"]+)"/)[1].split(/\s+/).map(Number);
    const height = Math.round(pixelWidth * vh / vw);
    const page = await browser.newPage({ viewport: { width: pixelWidth, height } });
    await page.setContent(`<style>${font}html,body{margin:0}svg{display:block;width:100vw;height:100vh}${hide}{display:none}</style>${svg}`, { waitUntil: 'networkidle' });
    const dir = path.join(assets, `${name}.imageset`);
    fs.mkdirSync(dir, { recursive: true });
    await page.screenshot({ path: path.join(dir, `${name}.png`), omitBackground: true });
    fs.writeFileSync(path.join(dir, 'Contents.json'), JSON.stringify({
      images: [{ filename: `${name}.png`, idiom: 'universal' }],
      info: { author: 'xcode', version: 1 },
    }, null, 2) + '\n');
    await page.close();
  }

  // App icon: Coco on a sky-to-grass gradient, opaque, 1024×1024.
  const coco = fs.readFileSync(path.join(__dirname, 'coco.svg'), 'utf8');
  const page = await browser.newPage({ viewport: { width: 1024, height: 1024 } });
  await page.setContent(`<style>html,body{margin:0}body{width:1024px;height:1024px;display:flex;align-items:center;justify-content:center;background:linear-gradient(#8DD1FF,#C7EF9E)}svg{width:820px;height:820px}</style>${coco}`);
  await page.screenshot({ path: path.join(assets, 'AppIcon.appiconset/AppIcon.png') });
  await browser.close();
})();
