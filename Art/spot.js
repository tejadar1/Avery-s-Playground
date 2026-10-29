// Writes the Spot It rooms: Art/spot-<room>.svg (one <g class="part"> per layer, rendered one at a time by render.js)
// and AverysPlayground/Activities/SpotScenes.swift (where each thing is, for tapping). Run: node Art/spot.js
// Drawn flat and soft, like a Bluey episode: no outlines, pastel colors, a darker tone of each color for shading.
// Each thing that can change is its own layer; one with an "-alt" layer can change color too.
const fs = require('fs');
const path = require('path');
const W = 1600, H = 1200;

const rect = (x, y, w, h, r, fill, extra = '') => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${fill}"${extra}/>`;
const ellipse = (cx, cy, rx, ry, fill, extra = '') => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${fill}"${extra}/>`;
const circle = (cx, cy, r, fill) => ellipse(cx, cy, r, r, fill);
const p = (d, fill, extra = '') => `<path d="${d}" fill="${fill}"${extra}/>`;
const line = (d, color, w) => `<path d="${d}" fill="none" stroke="${color}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"/>`;
const shadow = (cx, cy, rx, ry = rx * 0.18) => ellipse(cx, cy, rx, ry, '#000', ' opacity="0.08"');

// A room: its background, then the things in it, back to front.
function room(name, background, things) {
  const parts = [`<g id="bg" class="part">${background}</g>`];
  const swift = [];
  for (const t of things) {
    parts.push(`<g id="${t.id}" class="part">${t.draw(t.colors)}</g>`);
    if (t.alt) parts.push(`<g id="${t.id}-alt" class="part">${t.draw(t.alt)}</g>`);
    const [x0, y0, x1, y1] = t.box;
    swift.push(`            Thing(id: "${t.id}", spot: CGPoint(x: ${((x0 + x1) / 2 / W).toFixed(3)}, y: ${((y0 + y1) / 2 / H).toFixed(3)}), `
      + `size: ${(Math.max(x1 - x0, (y1 - y0)) / W).toFixed(3)}, canHide: ${t.canHide !== false}, canRecolor: ${!!t.alt}),`);
  }
  fs.writeFileSync(path.join(__dirname, `spot-${name}.svg`), `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}">
  <!-- A Spot It room, written by spot.js (edit that, not this). -->
${parts.join('\n')}
</svg>
`);
  return `        Room(name: "${name}", things: [\n${swift.join('\n')}\n        ]),`;
}

// ---- The living room ----
const living = (() => {
  const wall = '#BFE0D6', wallDark = '#AED3C8', floor = '#E7C49B', floorDark = '#D9B386';
  const bg = rect(0, 0, W, H, 0, wall)
    + rect(0, 0, W, 60, 0, '#F6F1E7') + rect(0, 54, W, 10, 0, wallDark)
    + rect(0, 820, W, 380, 0, floor) + [880, 950, 1030, 1120].map((y) => line(`M0 ${y} L${W} ${y}`, floorDark, 4)).join('')
    + [200, 520, 840, 1160, 1480].map((x, i) => line(`M${x + (i % 2) * 140} 820 L${x + (i % 2) * 140} 880 M${x} 880 L${x} 950 M${x + 160} 950 L${x + 160} 1030 M${x + 60} 1030 L${x + 60} 1120 M${x + 220} 1120 L${x + 220} 1200`, floorDark, 4)).join('')
    + rect(0, 800, W, 28, 0, '#F6F1E7')
    // the window: sky, a hill, a tree and a fence outside
    + rect(900, 150, 400, 420, 18, '#F6F1E7') + rect(920, 170, 360, 380, 8, '#BDE2F6')
    + p('M920 430 Q1040 380 1180 420 Q1240 436 1280 430 L1280 550 L920 550Z', '#A7D38E') + p('M920 480 Q1100 450 1280 490 L1280 550 L920 550Z', '#93C47A')
    + rect(1180, 340, 18, 110, 4, '#9C7653') + circle(1189, 320, 52, '#86BE6E') + circle(1160, 345, 34, '#7CB463')
    + [940, 990, 1040, 1090].map((x) => rect(x, 470, 14, 70, 4, '#F6F1E7')).join('') + rect(930, 490, 190, 10, 3, '#F6F1E7')
    + rect(1094, 170, 12, 380, 0, '#F6F1E7') + rect(920, 354, 360, 12, 0, '#F6F1E7')
    + ellipse(1000, 230, 50, 20, '#fff', ' opacity="0.9"') + ellipse(1040, 220, 38, 18, '#fff', ' opacity="0.9"')
    + rect(880, 560, 440, 22, 6, '#E9E2D3')
    // the coffee table and the bookshelf stay; what's on them can change
    + shadow(1450, 870, 140, 22) + rect(1330, 320, 240, 550, 14, '#C99A6B') + rect(1348, 340, 204, 510, 8, '#B6865A')
    + [500, 670].map((y) => rect(1348, y, 204, 18, 4, '#C99A6B')).join('');
  const things = [
    { id: 'curtains', box: [850, 120, 1350, 600], colors: ['#F2A38E', '#E58B76'], alt: ['#B9A6E3', '#A08DD0'],
      draw: ([c, d]) => rect(860, 120, 480, 20, 10, '#9C7653')
        + p('M870 140 Q930 140 960 140 Q930 360 960 590 L870 590 Q890 360 870 140Z', c) + line('M900 160 Q890 360 905 580 M935 160 Q920 360 935 580', d, 8)
        + p('M1240 140 Q1300 140 1330 140 Q1310 360 1330 590 L1240 590 Q1270 360 1240 140Z', c) + line('M1265 160 Q1280 360 1268 580 M1300 160 Q1312 360 1300 580', d, 8) },
    { id: 'frame', box: [290, 170, 540, 350], colors: ['#F6C945', '#8FCB6E'], alt: ['#EE6A8A', '#6FB8F0'],
      draw: ([sun, hill]) => rect(290, 170, 250, 180, 10, '#9C7653') + rect(308, 188, 214, 144, 4, '#DDF0FA')
        + p('M308 300 Q380 250 450 290 Q490 310 522 300 L522 332 L308 332Z', hill) + circle(470, 230, 24, sun) },
    { id: 'clock', box: [640, 150, 760, 270], colors: ['#F2A38E'], alt: ['#7CC3E8'],
      draw: ([c]) => circle(700, 210, 60, c) + circle(700, 210, 46, '#FFFDF7') + line('M700 210 L700 178 M700 210 L724 222', '#5A4A42', 7) + circle(700, 210, 6, '#5A4A42') },
    { id: 'garland', box: [100, 70, 820, 160], colors: ['#F6C945', '#EE8AA8', '#7CC3E8'], alt: ['#8FCB6E', '#B9A6E3', '#F2A38E'],
      draw: (cs) => line('M100 80 Q460 150 820 80', '#9C7653', 4)
        + [...Array(8)].map((_, i) => { const x = 140 + i * 88, y = 80 + 70 * Math.sin(Math.PI * (x - 100) / 720) * 0.75; return p(`M${x - 26} ${y} L${x + 26} ${y} L${x} ${y + 50}Z`, cs[i % 3]); }).join('') },
    { id: 'lamp', box: [770, 290, 900, 860], canHide: false, colors: ['#F6B04F', '#E39A3A'], alt: ['#6FC2B7', '#57AA9F'],
      draw: ([c, d]) => shadow(835, 858, 70) + rect(826, 380, 16, 470, 8, '#8A6A55') + ellipse(835, 850, 60, 14, '#8A6A55')
        + p('M770 390 L900 390 L870 290 L800 290Z', c) + p('M835 290 L870 290 L900 390 L850 390Z', d) },
    { id: 'couch', box: [110, 500, 770, 870], canHide: false, colors: ['#7AA7DB', '#6390C6'], alt: ['#EE8AA8', '#D9708F'],
      draw: ([c, d]) => shadow(440, 868, 330, 30) + rect(150, 500, 580, 230, 60, d) + rect(110, 650, 660, 170, 50, c)
        + rect(110, 610, 110, 220, 50, d) + rect(660, 610, 110, 220, 50, d) + rect(200, 640, 220, 90, 34, c) + rect(440, 640, 220, 90, 34, c)
        + rect(140, 820, 26, 46, 8, '#8A6A55') + rect(714, 820, 26, 46, 8, '#8A6A55') },
    { id: 'cushion1', box: [210, 540, 370, 690], colors: ['#F6C945', '#E3B12F'], alt: ['#8FCB6E', '#76B357'],
      draw: ([c, d]) => p('M220 560 Q290 530 360 560 Q372 620 356 680 Q290 700 224 680 Q208 620 220 560Z', c) + circle(290, 615, 10, d) },
    { id: 'cushion2', box: [500, 540, 660, 690], colors: ['#F2A38E', '#E58B76'], alt: ['#B9A6E3', '#A08DD0'],
      draw: ([c, d]) => p('M510 560 Q580 530 650 560 Q662 620 646 680 Q580 700 514 680 Q498 620 510 560Z', c) + line('M520 600 L640 600 M520 640 L640 640', d, 8) },
    { id: 'blanket', box: [600, 600, 770, 790], colors: ['#B9A6E3', '#A08DD0'], alt: ['#F6C945', '#E3B12F'],
      draw: ([c, d]) => p('M620 610 Q700 590 760 620 L770 780 Q700 800 640 770 Q600 700 620 610Z', c) + line('M640 640 L750 660 M635 690 L755 712 M640 740 L750 760', d, 7) },
    { id: 'plant', box: [1180, 600, 1320, 860], colors: ['#7CB463', '#6AA152'], alt: ['#EE8AA8', '#D9708F'],
      draw: ([c, d]) => shadow(1250, 858, 60) + p('M1205 760 L1295 760 L1280 860 L1220 860Z', '#E58B76')
        + p('M1250 760 Q1180 700 1190 620 Q1240 660 1250 760Z', c) + p('M1250 760 Q1320 690 1310 610 Q1260 650 1250 760Z', d)
        + p('M1250 760 Q1240 670 1262 600 Q1282 680 1250 760Z', c) },
    { id: 'books', box: [1350, 400, 1550, 500], colors: ['#EE6A8A', '#7CC3E8', '#F6C945', '#8FCB6E'], alt: ['#8FCB6E', '#F6C945', '#B9A6E3', '#F2A38E'],
      draw: (cs) => [0, 1, 2, 3, 4, 5].map((i) => rect(1360 + i * 30, 410 + (i % 3) * 10, 26, 90 - (i % 3) * 10, 4, cs[i % 4])).join('') },
    { id: 'shelfbear', box: [1380, 560, 1480, 670], colors: ['#C9915E', '#B27A48'],
      draw: ([c, d]) => circle(1405, 582, 14, c) + circle(1455, 582, 14, c) + circle(1430, 610, 34, c) + ellipse(1430, 650, 40, 22, d) + circle(1418, 604, 5, '#4A3A33') + circle(1442, 604, 5, '#4A3A33') + ellipse(1430, 618, 10, 7, '#E9C9A8') },
    { id: 'vase', box: [1420, 730, 1520, 850], colors: ['#7CC3E8', '#5FAAD3'], alt: ['#F6C945', '#E3B12F'],
      draw: ([c, d]) => p('M1450 850 Q1430 800 1450 760 L1490 760 Q1510 800 1490 850Z', c) + p('M1470 760 L1490 760 Q1510 800 1490 850 L1470 850Z', d)
        + line('M1470 760 L1458 720 M1470 760 L1484 715', '#7CB463', 6) + circle(1458, 716, 12, '#EE6A8A') + circle(1484, 711, 12, '#F6C945') },
    { id: 'rug', box: [300, 960, 1020, 1180], canHide: false, colors: ['#F6C945', '#EBB532'], alt: ['#8FCB6E', '#79B65B'],
      draw: ([c, d]) => ellipse(660, 1080, 360, 100, c) + ellipse(660, 1080, 280, 70, d) + ellipse(660, 1080, 200, 46, c) },
    { id: 'table', box: [410, 900, 910, 1030], canHide: false, colors: [],  // never changes; drawn over the rug
      draw: () => shadow(660, 1010, 290, 40) + rect(410, 900, 500, 34, 14, '#B98656') + rect(420, 930, 480, 12, 6, '#A0703F')
        + rect(440, 934, 26, 90, 8, '#A0703F') + rect(854, 934, 26, 90, 8, '#A0703F') },
    { id: 'cup', box: [470, 840, 540, 905], colors: ['#EE6A8A', '#D9547A'], alt: ['#7CC3E8', '#5FAAD3'],
      draw: ([c, d]) => rect(478, 850, 48, 52, 10, c) + line('M526 862 Q546 870 528 890', d, 8) + ellipse(502, 852, 24, 6, '#8A5A3A') },
    { id: 'fruit', box: [600, 820, 740, 905], colors: ['#E8504A', '#F6C945'], alt: ['#8FCB6E', '#B9A6E3'],
      draw: ([a, b]) => circle(640, 858, 26, a) + circle(690, 852, 26, b) + circle(668, 838, 22, '#8FCB6E') + p('M600 870 L740 870 Q730 905 670 905 Q610 905 600 870Z', '#7CC3E8') },
    { id: 'book', box: [780, 880, 880, 905], colors: ['#B9A6E3', '#A08DD0'], alt: ['#F2A38E', '#E58B76'],
      draw: ([c, d]) => rect(780, 884, 96, 18, 4, c) + rect(780, 884, 96, 6, 3, d) },
    { id: 'ball', box: [1110, 1020, 1210, 1120], colors: ['#EE6A8A', '#fff'], alt: ['#7CC3E8', '#fff'],
      draw: ([c, s]) => shadow(1160, 1112, 46) + circle(1160, 1070, 46, c) + p('M1130 1035 Q1165 1070 1130 1105', 'none', ` stroke="${s}" stroke-width="10"`) + p('M1190 1035 Q1155 1070 1190 1105', 'none', ` stroke="${s}" stroke-width="10"`) },
    { id: 'blocks', box: [130, 1000, 300, 1110], colors: ['#F2A38E', '#7CC3E8', '#F6C945'], alt: ['#8FCB6E', '#B9A6E3', '#EE6A8A'],
      draw: ([a, b, c]) => shadow(215, 1108, 90) + rect(140, 1040, 70, 70, 8, a) + rect(214, 1040, 70, 70, 8, b) + rect(176, 970, 70, 70, 8, c) },
    { id: 'teddy', box: [1280, 920, 1440, 1110], colors: ['#C9915E', '#B27A48'], alt: ['#EEB5C9', '#D99AB0'],
      draw: ([c, d]) => shadow(1360, 1106, 80) + circle(1310, 945, 24, c) + circle(1410, 945, 24, c) + circle(1360, 985, 56, c)
        + ellipse(1360, 1065, 70, 50, d) + circle(1300, 1090, 22, c) + circle(1420, 1090, 22, c) + circle(1340, 975, 7, '#4A3A33') + circle(1380, 975, 7, '#4A3A33') + ellipse(1360, 1000, 18, 12, '#E9C9A8') },
    { id: 'sock', box: [960, 1120, 1060, 1180], colors: ['#7CC3E8', '#5FAAD3'], alt: ['#F6C945', '#E3B12F'],
      draw: ([c, d]) => p('M970 1130 L1010 1130 L1012 1150 Q1050 1150 1052 1166 Q1050 1180 1010 1178 L980 1178 Q966 1170 970 1150Z', c) + rect(966, 1126, 48, 12, 5, d) },
  ];
  return room('living', bg, things);
})();

// ---- The bedroom ----
const bedroom = (() => {
  const wall = '#E3D4F0', wallDark = '#D3C1E6', floor = '#E7C49B', floorDark = '#D9B386';
  const bg = rect(0, 0, W, H, 0, wall) + rect(0, 0, W, 60, 0, '#F6F1E7') + rect(0, 54, W, 10, 0, wallDark)
    + [...Array(9)].map((_, i) => rect(i * 180 + 60, 64, 90, 756, 0, '#DCCBEB')).join('')  // soft stripes
    + rect(0, 840, W, 360, 0, floor) + [900, 980, 1070, 1160].map((y) => line(`M0 ${y} L${W} ${y}`, floorDark, 4)).join('')
    + rect(0, 820, W, 28, 0, '#F6F1E7')
    // the window, with a sunny garden
    + rect(1000, 170, 300, 340, 18, '#F6F1E7') + rect(1018, 188, 264, 304, 8, '#BDE2F6')
    + p('M1018 400 Q1120 360 1282 400 L1282 492 L1018 492Z', '#A7D38E') + circle(1220, 250, 34, '#F6D365')
    + rect(1144, 188, 12, 304, 0, '#F6F1E7') + rect(1018, 334, 264, 12, 0, '#F6F1E7') + rect(980, 500, 340, 20, 6, '#E9E2D3')
    // the wardrobe and the shelf over the bed stay; what's on them can change
    + shadow(1460, 890, 140, 22) + rect(1340, 240, 240, 650, 14, '#C99A6B') + rect(1358, 260, 98, 600, 8, '#B6865A') + rect(1464, 260, 98, 600, 8, '#B6865A')
    + circle(1440, 560, 10, '#8A6A55') + circle(1480, 560, 10, '#8A6A55')
    + rect(150, 360, 520, 22, 6, '#B98656') + p('M190 382 L210 382 L200 420Z', '#A0703F') + p('M610 382 L630 382 L620 420Z', '#A0703F')
    + shadow(890, 885, 90, 16) + rect(820, 700, 140, 180, 12, '#C99A6B') + rect(830, 760, 120, 10, 4, '#B6865A') + circle(890, 820, 8, '#8A6A55');
  const things = [
    { id: 'curtains', box: [960, 140, 1340, 540], colors: ['#8FCB6E', '#79B65B'], alt: ['#F6C945', '#E3B12F'],
      draw: ([c, d]) => rect(960, 140, 380, 18, 9, '#9C7653')
        + p('M970 158 L1050 158 Q1030 340 1056 530 L970 530 Q990 340 970 158Z', c) + line('M995 175 Q990 340 1000 520 M1025 175 Q1015 340 1028 520', d, 7)
        + p('M1250 158 L1330 158 Q1312 340 1330 530 L1244 530 Q1270 340 1250 158Z', c) + line('M1275 175 Q1282 340 1272 520 M1305 175 Q1312 340 1302 520', d, 7) },
    { id: 'stars', box: [690, 90, 960, 260], colors: ['#F6C945'], alt: ['#EE8AA8'],
      draw: ([c]) => [[720, 130, 26], [800, 200, 20], [880, 120, 30], [930, 220, 18], [760, 240, 14]].map(([x, y, r]) => {
        let d = ''; for (let k = 0; k < 10; k++) { const a = -Math.PI / 2 + k * Math.PI / 5, rr = k % 2 ? r * 0.45 : r; d += (k ? 'L' : 'M') + (x + rr * Math.cos(a)).toFixed(1) + ' ' + (y + rr * Math.sin(a)).toFixed(1); }
        return p(d + 'Z', c); }).join('') },
    { id: 'drawing', box: [170, 130, 330, 290], colors: ['#EE6A8A', '#7CC3E8'], alt: ['#8FCB6E', '#F6C945'],
      draw: ([a, b]) => rect(170, 130, 160, 160, 4, '#FFFDF7', ' transform="rotate(-4 250 210)"') + rect(232, 122, 36, 16, 3, '#F2E3A0', ' transform="rotate(-4 250 210)"')
        + circle(230, 220, 34, a) + p('M270 260 L300 180 L320 260Z', b) + line('M190 270 L320 262', '#8FCB6E', 6) },
    { id: 'shelfdino', box: [200, 270, 330, 362], colors: ['#8FCB6E', '#76B357'], alt: ['#F2A38E', '#E58B76'],
      draw: ([c, d]) => p('M210 360 L210 320 Q220 290 260 296 L300 296 Q318 280 330 296 Q330 312 316 316 L310 360Z', c) + p('M236 296 L246 280 L256 296 M266 296 L276 280 L286 296', d) + circle(318, 302, 4, '#4A3A33') },
    { id: 'shelfball', box: [380, 300, 450, 362], colors: ['#F6C945', '#EE6A8A'], alt: ['#7CC3E8', '#B9A6E3'],
      draw: ([a, b]) => circle(415, 330, 30, a) + p('M385 330 Q415 300 445 330 Q415 360 385 330Z', b) },
    { id: 'shelfbooks', box: [490, 270, 640, 362], colors: ['#7CC3E8', '#F2A38E', '#B9A6E3'], alt: ['#F6C945', '#8FCB6E', '#EE6A8A'],
      draw: (cs) => [0, 1, 2, 3].map((i) => rect(500 + i * 32, 280 + (i % 2) * 12, 28, 80 - (i % 2) * 12, 4, cs[i % 3])).join('') + rect(630, 330, 14, 30, 2, '#9C7653') },
    { id: 'kite', box: [1150, 560, 1310, 800], colors: ['#EE6A8A', '#F6C945'], alt: ['#7CC3E8', '#8FCB6E'],
      draw: ([a, b]) => p('M1230 570 L1300 650 L1230 730 L1160 650Z', a) + p('M1230 570 L1300 650 L1230 650Z', b) + p('M1160 650 L1230 730 L1230 650Z', b)
        + line('M1230 730 Q1210 760 1240 780 Q1260 800 1236 820', '#9C7653', 4) + [760, 790].map((y) => p(`M1222 ${y} l-14 -8 l0 16Z M1222 ${y} l14 -8 l0 16Z`, a)).join('') },
    { id: 'bed', box: [80, 470, 800, 900], canHide: false, colors: ['#7CC3E8', '#5FAAD3'], alt: ['#EE8AA8', '#D9708F'],
      draw: ([c, d]) => shadow(440, 895, 360, 30) + rect(90, 480, 80, 410, 20, '#B98656') + rect(720, 600, 70, 290, 20, '#B98656')
        + rect(140, 640, 620, 200, 20, '#F6F1E7') + p('M300 620 L760 620 L760 820 Q530 850 300 820Z', c) + p('M300 760 L760 760 L760 820 Q530 850 300 820Z', d)
        + line('M360 660 L360 820 M440 660 L440 830 M520 660 L520 832 M600 660 L600 830 M680 660 L680 826', d, 6) },
    { id: 'pillow', box: [160, 560, 320, 670], colors: ['#FFFDF7', '#EDE6D8'], alt: ['#F6C945', '#E3B12F'],
      draw: ([c, d]) => p('M170 580 Q240 550 310 580 Q324 630 306 662 Q240 676 176 662 Q158 630 170 580Z', c) + line('M190 600 Q240 590 290 600', d, 6) },
    { id: 'bunny', box: [420, 520, 540, 640], colors: ['#F7D9E3', '#EEB5C9'], alt: ['#D8E9C8', '#B9D59E'],
      draw: ([c, d]) => ellipse(462, 545, 12, 30, c) + ellipse(498, 545, 12, 30, c) + ellipse(462, 548, 5, 20, d) + ellipse(498, 548, 5, 20, d)
        + circle(480, 590, 32, c) + ellipse(480, 630, 40, 16, d) + circle(468, 584, 5, '#4A3A33') + circle(492, 584, 5, '#4A3A33') + circle(480, 598, 5, d) },
    { id: 'lamp', box: [840, 580, 940, 700], colors: ['#F6B04F', '#E39A3A'], alt: ['#B9A6E3', '#A08DD0'],
      draw: ([c, d]) => rect(882, 640, 16, 60, 6, '#8A6A55') + ellipse(890, 700, 34, 8, '#8A6A55') + p('M845 645 L935 645 L915 585 L865 585Z', c) + p('M890 585 L915 585 L935 645 L900 645Z', d) },
    { id: 'clock', box: [900, 650, 950, 700], colors: ['#EE6A8A'], alt: ['#8FCB6E'],
      draw: ([c]) => circle(925, 678, 22, c) + circle(925, 678, 15, '#FFFDF7') + line('M925 678 L925 668 M925 678 L933 682', '#5A4A42', 4) },
    { id: 'rug', box: [480, 940, 1120, 1180], canHide: false, colors: ['#EE8AA8', '#D9708F'], alt: ['#7CC3E8', '#5FAAD3'],
      draw: ([c, d]) => ellipse(800, 1060, 320, 100, c) + [0, 1, 2, 3, 4, 5, 6, 7].map((i) => circle(560 + i * 68, 1060 + (i % 2 ? 30 : -30), 16, d)).join('') },
    { id: 'toybox', box: [1080, 830, 1320, 1010], canHide: false, colors: ['#F2A38E', '#E58B76'], alt: ['#8FCB6E', '#76B357'],
      draw: ([c, d]) => shadow(1200, 1006, 130, 18) + rect(1090, 880, 220, 124, 14, c) + rect(1090, 880, 220, 26, 10, d) + circle(1200, 950, 18, '#F6C945') },
    { id: 'robot', box: [1120, 820, 1180, 890], colors: ['#7CC3E8', '#5FAAD3'], alt: ['#F6C945', '#E3B12F'],
      draw: ([c, d]) => rect(1124, 830, 52, 50, 8, c) + rect(1146, 816, 8, 16, 3, d) + circle(1140, 850, 6, '#fff') + circle(1160, 850, 6, '#fff') + rect(1136, 864, 28, 6, 3, d) },
    { id: 'toyduck', box: [1220, 830, 1290, 890], colors: ['#F6C945', '#E3B12F'], alt: ['#EE8AA8', '#D9708F'],
      draw: ([c, d]) => ellipse(1252, 870, 32, 20, c) + circle(1270, 846, 16, c) + p('M1282 846 L1298 850 L1282 856Z', '#F2A38E') + circle(1272, 842, 3.5, '#4A3A33') + ellipse(1244, 866, 14, 8, d) },
    { id: 'slippers', box: [600, 950, 760, 1010], colors: ['#B9A6E3', '#A08DD0'], alt: ['#F6C945', '#E3B12F'],
      draw: ([c, d]) => ellipse(640, 980, 38, 20, c) + ellipse(716, 984, 38, 20, c) + ellipse(652, 976, 22, 12, d) + ellipse(728, 980, 22, 12, d) },
    { id: 'drum', box: [180, 960, 360, 1110], colors: ['#E8504A', '#C83C38'], alt: ['#6FB8F0', '#4F9AD6'],
      draw: ([c, d]) => shadow(270, 1106, 90) + rect(190, 990, 160, 110, 14, c) + ellipse(270, 990, 80, 24, '#FFFDF7')
        + line('M200 1000 L240 1090 L280 1000 L320 1090 L340 1010', d, 6) + line('M340 940 L300 975 M370 950 L320 980', '#C99A6B', 8) },
    { id: 'cat', box: [840, 990, 1000, 1090], colors: ['#F6B04F', '#E39A3A'], alt: ['#B7B1AE', '#9C9591'],
      draw: ([c, d]) => ellipse(920, 1050, 72, 38, c) + circle(870, 1030, 30, c) + p('M848 1012 L852 988 L868 1004Z M884 1004 L892 984 L900 1008Z', c)
        + line('M992 1050 Q1010 1020 990 1000', c, 14) + line('M862 1030 Q868 1036 874 1030 M880 1028 Q886 1034 892 1028', '#4A3A33', 3) + line('M900 1060 L960 1050 M910 1074 L966 1066', d, 6) },
  ];
  return room('bedroom', bg, things);
})();

fs.writeFileSync(path.join(__dirname, '..', 'AverysPlayground', 'Activities', 'SpotScenes.swift'), `import CoreGraphics

// Written by Art/spot.js (edit that, not this): the rooms in Spot It and where each thing that can change is.
// Spots are fractions of the picture; size is the thing's width or height, whichever is bigger, as a share of the width.
extension SpotTheDifference {
    static let rooms = [
${living}
${bedroom}
    ]
}
`);
console.log('ok');
