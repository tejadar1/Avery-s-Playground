// Writes the Puzzles pictures (Art/puzzles/<name>.svg, 800×600): silly scenes of Coco made from the app's own art.
// Run: node Art/puzzles.js, then render with node Art/render.js (they become Puzzle-<name>).
const fs = require('fs');
const path = require('path');

const art = (file) => fs.readFileSync(path.join(__dirname, file), 'utf8');
const O = '#4A2C2A';
let copies = 0;

// Puts an SVG file in the scene at x, y, w wide; ids get a prefix so copies don't clash.
function place(file, x, y, w, { rotate = 0, flip = false } = {}) {
  const svg = art(file);
  const [, , vw, vh] = svg.match(/viewBox="([^"]+)"/)[1].split(/\s+/).map(Number);
  const h = w * vh / vw;
  const p = `c${copies++}-`;
  const inner = svg.replace(/^[\s\S]*?<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '')
    .replace(/id="([^"]+)"/g, `id="${p}$1"`).replace(/url\(#([^)]+)\)/g, `url(#${p}$1)`).replace(/href="#([^"]+)"/g, `href="#${p}$1"`);
  const cx = x + w / 2, cy = y + h / 2;
  const turn = `rotate(${rotate} ${cx} ${cy})` + (flip ? ` translate(${2 * cx} 0) scale(-1 1)` : '');
  return `<g transform="${turn}"><svg x="${x}" y="${y}" width="${w}" height="${h}" viewBox="0 0 ${vw} ${vh}">${inner}</svg></g>`;
}

const coco = (x, y, w, options) => place('coco.svg', x, y, w, options);
const pic = (name, x, y, w, options) => place(`pictures/${name}.svg`, x, y, w, options);
const cloud = (x, y, s) => `<path d="M${x} ${y} a${22 * s} ${22 * s} 0 0 1 ${40 * s} -${12 * s} a${30 * s} ${30 * s} 0 0 1 ${56 * s} ${4 * s} a${20 * s} ${20 * s} 0 0 1 ${10 * s} ${38 * s} h-${110 * s} a${16 * s} ${16 * s} 0 0 1 ${4 * s} -${30 * s}Z" fill="#fff" stroke="${O}" stroke-width="4"/>`;
const sky = `<rect width="800" height="600" fill="#BFE6FA"/>${cloud(70, 110, 1)}${cloud(560, 80, 1.2)}`;
const hills = `<path d="M0 470 Q200 400 420 460 T800 440 V600 H0Z" fill="#9BD37F" stroke="${O}" stroke-width="5"/><path d="M0 520 Q260 480 520 520 T800 510 V600 H0Z" fill="#7CC063"/>`;
const confetti = Array.from({ length: 40 }, (_, i) =>
  `<rect x="${(i * 137) % 800}" y="${(i * 89) % 560}" width="12" height="7" rx="2" fill="${['#F49AC1', '#F6C945', '#8FD0C8', '#9E8CE6'][i % 4]}" transform="rotate(${i * 29} ${(i * 137) % 800} ${(i * 89) % 560})"/>`).join('');

const scenes = {
  // Bath time, with a rubber duck for a hat.
  bath: `<rect width="800" height="600" fill="#CFEFF2"/>
    ${Array.from({ length: 8 }, (_, i) => `<path d="M${i * 100} 0 V430" stroke="#B5E0E5" stroke-width="3"/>`).join('')}
    <rect y="430" width="800" height="170" fill="#E8D6C0"/><path d="M0 430 H800" stroke="${O}" stroke-width="5"/>
    ${coco(250, 110, 300)}${pic('bathtub', 150, 200, 500)}
    ${pic('duck', 285, 40, 120, { rotate: -12 })}
    ${pic('bubbles', 70, 120, 160)}${pic('bubbles', 600, 160, 150)}${pic('bubbles', 470, 40, 110)}`,

  // A party in a top hat and sunglasses.
  party: `<rect width="800" height="600" fill="#FCE3EE"/>${confetti}
    <rect y="470" width="800" height="130" fill="#F6C9DA"/><path d="M0 470 H800" stroke="${O}" stroke-width="5"/>
    ${coco(200, 150, 330)}
    ${pic('tophat', 250, 62, 160, { rotate: -12 })}
    ${pic('sunglasses', 280, 175, 170)}
    ${pic('cake', 520, 330, 220)}${pic('balloon', 40, 60, 170, { rotate: -8 })}${pic('balloon', 610, 30, 150, { rotate: 10 })}`,

  // A pizza bigger than Coco.
  pizza: `<rect width="800" height="600" fill="#FFF1C9"/>
    <rect y="460" width="800" height="140" fill="#E9B97A"/><path d="M0 460 H800" stroke="${O}" stroke-width="5"/>
    ${coco(60, 170, 300)}
    ${pic('pizza', 290, 110, 420, { rotate: 70 })}
    ${pic('heart', 150, 60, 90, { rotate: -12 })}${pic('heart', 260, 30, 70, { rotate: 10 })}${pic('heart', 330, 80, 55)}`,

  // Floating away on balloons.
  balloons: `${sky}${hills}${pic('sun', 640, 20, 140)}
    <g stroke="${O}" stroke-width="3" fill="none"><path d="M285 205 Q330 230 370 245"/><path d="M405 175 Q395 215 380 245"/><path d="M520 210 Q450 235 390 248"/></g>
    ${pic('balloon', 200, 40, 170, { rotate: -10 })}${pic('balloon', 320, 10, 170)}${pic('balloon', 440, 45, 170, { rotate: 10 })}
    ${coco(270, 190, 260, { rotate: 8 })}${pic('bird', 600, 230, 110, { flip: true })}`,

  // Riding Mochi, wearing a crown.
  mochi: `${sky}${hills}
    ${place('mochi.svg', 150, 250, 520)}
    ${coco(300, 140, 240, { rotate: -6 })}
    ${pic('crown', 345, 85, 110, { rotate: -12 })}${pic('flower', 60, 440, 100)}${pic('flower', 680, 450, 90)}`,

  // A ballet dancer with a tutu and a wand.
  ballet: `<rect width="800" height="600" fill="#E9DDF7"/>
    <path d="M0 0 H160 Q120 300 170 600 H0Z" fill="#E36A86" stroke="${O}" stroke-width="5"/><path d="M800 0 H640 Q680 300 630 600 H800Z" fill="#E36A86" stroke="${O}" stroke-width="5"/>
    <rect y="500" width="800" height="100" fill="#C9A27A"/><path d="M0 500 H800" stroke="${O}" stroke-width="5"/>
    ${coco(240, 140, 310)}${pic('tutu', 270, 320, 240)}
    ${pic('crown', 305, 60, 110, { rotate: -10 })}${pic('wand', 470, 210, 150, { rotate: 25 })}
    ${pic('sparkles', 540, 120, 110)}${pic('sparkles', 180, 170, 90)}`,

  // A day at the beach: sunhat, sunglasses and an ice cream.
  beach: `<rect width="800" height="600" fill="#BFE6FA"/>${cloud(80, 100, 0.9)}${pic('sun', 620, 20, 150)}
    <rect y="300" width="800" height="120" fill="#5DB4E6"/><path d="M0 330 Q40 320 80 330 T160 330 T240 330 T320 330 T400 330 T480 330 T560 330 T640 330 T720 330 T800 330" fill="none" stroke="#fff" stroke-width="4"/>
    <path d="M0 400 Q400 370 800 400 V600 H0Z" fill="#F4DCA0" stroke="${O}" stroke-width="5"/>
    ${pic('boat', 560, 200, 170)}${pic('umbrella', 40, 170, 300)}
    ${coco(290, 190, 300)}
    ${pic('sunhat', 300, 120, 200, { rotate: -10 })}${pic('sunglasses', 325, 215, 160)}
    ${pic('icecream', 560, 300, 140, { rotate: 15 })}${pic('sandals', 120, 470, 120)}`,

  // Surfing on the school bus roof, with friends riding inside and a frog driving.
  bus: `${sky}<rect y="500" width="800" height="100" fill="#8E8E9A"/><path d="M0 500 H800" stroke="${O}" stroke-width="5"/>
    ${Array.from({ length: 6 }, (_, i) => `<rect x="${i * 150 + 20}" y="545" width="80" height="10" rx="5" fill="#fff"/>`).join('')}
    ${coco(250, 30, 230, { rotate: -8 })}
    ${pic('bus', 120, 122, 560)}
    ${pic('cat', 186, 300, 92)}${pic('pig', 292, 300, 92)}${pic('duck', 396, 300, 92)}${pic('frog', 512, 298, 100)}
    ${pic('sunglasses', 280, 82, 130, { rotate: -8 })}`,
};

for (const [name, body] of Object.entries(scenes)) {
  fs.writeFileSync(path.join(__dirname, 'puzzles', `${name}.svg`),
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 600">\n${body}\n</svg>\n`);
}
