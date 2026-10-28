// Writes Art/doll.svg, the Dress Up doll: one <g class="part"> per layer, each rendered to its own image by render.js.
// Tinted parts are drawn in white and grays (the app multiplies them by skin, hair, eye or clothes color); "-under"
// and "-over" parts keep their own colors and go below and above it. Run: node Art/doll.js Art/doll.svg
// A softer, storybook look than the rest of the app: thin outlines in a darker tone of each color, and blurred shading.
const fs = require('fs');
const f = (n) => +n.toFixed(1);
const SKIN_LINE = '#b98a7c', TINT_LINE = '#8f8f8f', W = 4;
const BASE = '#f2f2f2', SHADE = '#c4c4c4', SKIN_SHADE = '#dcb4a6';
const HEAD = 'rotate(-3 500 250)';  // her head tilts a little

let ids = 0;
function smooth(pts, per = 12) {  // Catmull-Rom through [x, y, r]
  const out = [], p = [pts[0], ...pts, pts[pts.length - 1]];
  for (let i = 1; i < p.length - 2; i++) {
    for (let k = 0; k < per; k++) {
      const t = k / per, t2 = t * t, t3 = t2 * t;
      const c = (j) => 0.5 * ((2 * p[i][j]) + (-p[i - 1][j] + p[i + 1][j]) * t + (2 * p[i - 1][j] - 5 * p[i][j] + 4 * p[i + 1][j] - p[i + 2][j]) * t2 + (-p[i - 1][j] + 3 * p[i][j] - 3 * p[i + 1][j] + p[i + 2][j]) * t3);
      out.push([c(0), c(1), p[i][2] + (p[i + 1][2] - p[i][2]) * t]);
    }
  }
  out.push(pts[pts.length - 1]);
  return out;
}
function normals(s) {
  return s.map((_, i) => {
    const a = s[Math.max(0, i - 1)], b = s[Math.min(s.length - 1, i + 1)];
    const dx = b[0] - a[0], dy = b[1] - a[1], l = Math.hypot(dx, dy) || 1;
    return [-dy / l, dx / l];
  });
}
const pts = (list) => list.map((q) => f(q[0]) + ' ' + f(q[1])).join(' L');
// A tapered limb through [x, y, radius] points, with round ends.
function limb(points) {
  const s = smooth(points), n = normals(s);
  const L = s.map((p, i) => [p[0] + n[i][0] * p[2], p[1] + n[i][1] * p[2]]);
  const R = s.map((p, i) => [p[0] - n[i][0] * p[2], p[1] - n[i][1] * p[2]]).reverse();
  const e = f(s[s.length - 1][2]), b = f(s[0][2]);
  return `M${pts(L)} A${e} ${e} 0 0 0 ${pts([R[0]])} L${pts(R)} A${b} ${b} 0 0 0 ${pts([L[0]])}Z`;
}
// A line down one side of a limb (negative is the right-hand side): where the shading goes.
function edge(points, at) {
  const s = smooth(points), n = normals(s);
  return 'M' + pts(s.map((p, i) => [p[0] + n[i][0] * p[2] * at, p[1] + n[i][1] * p[2] * at]));
}
const grow = (points, by, from = 0, to = points.length) => points.slice(from, to).map(([x, y, r]) => [x, y, r + by]);
const path = (d, fill, line, sw = W) => `<path d="${d}" fill="${fill}"${line ? ` stroke="${line}" stroke-width="${sw}" stroke-linejoin="round" stroke-linecap="round"` : ''}/>`;
const stroke = (d, color, sw, extra = '') => `<path d="${d}" fill="none" stroke="${color}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round"${extra}/>`;
// Shapes under one outline (outline everything, then fill on top), with blurred shading kept inside them.
function soft(paths, fill, line, shading = '') {
  const id = 'c' + ids++;
  return `<g stroke="${line}" stroke-width="${2 * W}" stroke-linejoin="round" fill="${line}">${paths.map((d) => `<path d="${d}"/>`).join('')}</g>`
    + `<g fill="${fill}">${paths.map((d) => `<path d="${d}"/>`).join('')}</g>`
    + (shading && `<clipPath id="${id}">${paths.map((d) => `<path d="${d}"/>`).join('')}</clipPath><g clip-path="url(#${id})"><g filter="url(#blur)">${shading}</g></g>`);
}
const part = (id, body) => `<g id="${id}" class="part">${body}</g>`;
const star = (x, y, r) => { let d = ''; for (let k = 0; k < 10; k++) { const a = -Math.PI / 2 + k * Math.PI / 5, rr = k % 2 ? r * 0.45 : r; d += (k ? 'L' : 'M') + f(x + rr * Math.cos(a)) + ' ' + f(y + rr * Math.sin(a)); } return d + 'Z'; };
const twinkle = (x, y, r) => `M${x} ${y - r} Q${x} ${y} ${x + r} ${y} Q${x} ${y} ${x} ${y + r} Q${x} ${y} ${x - r} ${y} Q${x} ${y} ${x} ${y - r}Z`;
const at = (points, i) => smooth(points)[i];

// ---- The pose: her weight on her left leg, the other knee relaxed, one hand on her hip ----
const leftArm = [[418, 322, 21], [408, 390, 17.5], [402, 452, 14.5], [399, 515, 12.5], [400, 576, 10.5]];
const rightArm = [[582, 320, 21], [612, 372, 17.5], [640, 428, 14.5], [612, 468, 12.5], [580, 492, 10.5]];
const leftHand = [[401, 580, 11.5], [402, 606, 12.5], [400, 632, 9]];
const leftThumb = [[411, 594, 6], [415, 614, 5]];
const rightHand = [[582, 492, 11.5], [562, 500, 11], [548, 506, 8.5]];
const leftLeg = [[462, 585, 40], [466, 700, 31], [474, 850, 21], [476, 945, 23], [480, 1075, 15.5], [484, 1146, 12]];
const rightLeg = [[538, 590, 40], [540, 705, 31], [536, 856, 21], [548, 950, 22.5], [560, 1068, 15.5], [566, 1136, 12]];
const leftFoot = [[484, 1146, 12], [482, 1180, 13], [478, 1206, 10]];
const rightFoot = [[566, 1136, 12], [569, 1168, 13], [572, 1194, 10]];
const torso = 'M482 268 C470 285 440 290 420 298 C402 305 398 330 404 352 C410 380 430 410 444 440 C450 455 452 465 450 478 C446 505 426 535 424 566 C424 600 458 620 500 622 C542 620 578 602 578 574 C576 540 556 506 550 478 C548 465 550 455 556 440 C570 410 590 380 596 352 C602 330 598 305 580 298 C560 290 530 285 518 268Z';
const neck = 'M481 200 L481 282 C490 292 510 292 519 282 L519 200Z';
const head = 'M500 86 C547 86 570 120 569 160 C568 198 546 234 500 248 C454 234 432 198 431 160 C430 120 453 86 500 86Z';

const parts = [];

// ---- Hair behind: long soft waves, tinted by her hair color ----
const hairBack = 'M500 68 C420 64 370 118 374 198 C376 252 356 296 348 350 C338 412 346 470 362 512 Q372 540 392 528 Q404 552 424 536 Q440 552 456 530 L544 530 Q560 552 576 536 Q596 552 608 528 Q628 540 638 512 C654 470 662 412 652 350 C644 296 624 252 626 198 C630 118 580 64 500 68Z';
parts.push(part('hairBack', `<g transform="${HEAD}">` + soft([hairBack], BASE, TINT_LINE,
  stroke('M420 140 C400 240 380 340 392 520 M580 140 C600 240 620 340 608 520', SHADE, 30)
  + stroke('M388 260 C372 340 370 420 380 500 M612 260 C628 340 630 420 620 500', '#fff', 14))
  + stroke('M392 230 C380 300 374 380 384 470 M402 330 C396 390 398 450 410 520 M608 230 C620 300 626 380 616 470 M598 330 C604 390 602 450 590 520', '#d2d2d2', 2.5) + '</g>'));

// ---- Skin: the body under one outline, softly shaded, then the head on top ----
const bodyShapes = [torso, neck, limb(leftArm), limb(rightArm), limb(leftHand), limb(leftThumb), limb(rightHand), limb(leftLeg), limb(rightLeg), limb(leftFoot), limb(rightFoot)];
const bodyShade = [leftArm, rightArm, leftLeg, rightLeg].map((l) => stroke(edge(l, -1), SKIN_SHADE, 22)).join('')
  + stroke('M410 330 C420 380 440 420 452 470 C446 520 430 560 430 600 M590 330 C580 380 560 420 548 470 C554 520 570 560 570 600', SKIN_SHADE, 22)
  + stroke('M486 250 C494 270 506 270 514 250', SKIN_SHADE, 26) + stroke('M500 600 L500 640', SKIN_SHADE, 18);
parts.push(part('body', soft(bodyShapes, '#fff', SKIN_LINE, bodyShade)
  + stroke('M466 856 C472 862 480 862 484 856 M528 862 C534 868 542 866 546 860', SKIN_SHADE, 3)
  + stroke('M456 300 C468 306 482 304 492 300 M508 300 C518 304 532 306 544 300', SKIN_SHADE, 3.5)
  + stroke('M394 624 L394 636 M401 627 L401 640', SKIN_SHADE, 2.5)
  + `<g transform="${HEAD}">` + soft([head], '#fff', SKIN_LINE, stroke('M440 160 C446 210 470 240 500 250', SKIN_SHADE, 22) + stroke('M440 100 C470 92 530 92 560 100', SKIN_SHADE, 24))
  + stroke('M496 186 C493 196 492 200 494 203', '#d9b0a3', 2.5) + stroke('M491 204 C496 209 504 209 509 204', '#b98a7c', 3) + '</g>'));

// ---- Eyes: whites under, the iris tinted by eye color, then lashes, lips and blush on top ----
const eyes = [[470, -1], [530, 1]];
const eye = (x, d) => `M${x - 21 * d} 166 C${x - 12 * d} 151 ${x + 10 * d} 149 ${x + 21 * d} 160 C${x + 12 * d} 176 ${x - 8 * d} 178 ${x - 21 * d} 166Z`;
parts.push(part('eyes-under', `<g transform="${HEAD}">${eyes.map(([x, d]) => path(eye(x, d), '#fff')).join('')}</g>`));
parts.push(part('eyes', `<g transform="${HEAD}"><clipPath id="eyeClip">${eyes.map(([x, d]) => `<path d="${eye(x, d)}"/>`).join('')}</clipPath>`
  + `<radialGradient id="iris"><stop offset="0.35" stop-color="#fff"/><stop offset="1" stop-color="#8a8a8a"/></radialGradient>`
  + `<g clip-path="url(#eyeClip)">${eyes.map(([x]) => `<circle cx="${x}" cy="164" r="11" fill="url(#iris)" stroke="#6a6a6a" stroke-width="1.5"/>`).join('')}</g></g>`));
parts.push(part('eyes-over', `<g transform="${HEAD}"><radialGradient id="blush"><stop offset="0" stop-color="#f2849c" stop-opacity="0.5"/><stop offset="1" stop-color="#f2849c" stop-opacity="0"/></radialGradient>`
  + `<linearGradient id="lips" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e7798d"/><stop offset="1" stop-color="#d45a74"/></linearGradient>`
  + eyes.map(([x, d]) => `<circle cx="${x}" cy="164" r="5" fill="#2a1d1d"/><circle cx="${x + 3.5}" cy="160" r="3" fill="#fff"/><circle cx="${x - 3}" cy="168" r="1.4" fill="#fff" opacity="0.8"/>`
    + stroke(`M${x - 21 * d} 166 C${x - 12 * d} 151 ${x + 10 * d} 149 ${x + 21 * d} 160`, '#3a2626', 3.5)
    + stroke(`M${x + 21 * d} 160 L${x + 27 * d} 155 M${x + 17 * d} 156 L${x + 22 * d} 149 M${x + 12 * d} 154 L${x + 15 * d} 147`, '#3a2626', 2)
    + stroke(`M${x - 18 * d} 170 C${x - 6 * d} 177 ${x + 8 * d} 175 ${x + 18 * d} 165`, '#c99a8c', 1.5)
    + stroke(`M${x - 20 * d} 157 C${x - 8 * d} 144 ${x + 10 * d} 144 ${x + 20 * d} 153`, '#cfa8de', 5, ' opacity="0.45"')).join('')
  + `<ellipse cx="452" cy="197" rx="18" ry="11" fill="url(#blush)"/><ellipse cx="548" cy="197" rx="18" ry="11" fill="url(#blush)"/>`
  + path('M486 217 C492 212 497 212 500 214 C503 212 508 212 514 217 C506 220 494 220 486 217Z', 'url(#lips)', '#b84c66', 1.2)
  + path('M486 217 C492 227 508 227 514 217 C506 220 494 220 486 217Z', 'url(#lips)', '#b84c66', 1.2)
  + `<ellipse cx="503" cy="222" rx="5" ry="1.8" fill="#fff" opacity="0.6"/></g>`));

// ---- Hair in front: a side part, bangs swept across, soft locks over her shoulders, and the brows ----
const bangs = 'M536 82 C500 78 446 96 430 142 C422 172 424 202 432 230 C440 190 452 150 488 132 C512 122 530 106 536 82Z';
const crown = 'M536 82 C566 92 582 128 576 180 C574 196 572 210 568 224 C566 180 556 130 536 82Z';
const lockL = 'M434 180 C420 240 426 300 414 350 C406 384 408 410 420 432 C424 404 434 380 440 340 C446 290 446 240 444 200Z';
const lockR = 'M566 200 C580 260 574 310 590 360 C598 390 596 410 588 428 C578 400 566 370 560 330 C554 280 556 240 556 210Z';
parts.push(part('hairFront', `<g transform="${HEAD}">` + soft([bangs, crown, lockL, lockR], BASE, TINT_LINE,
  stroke('M440 150 C450 130 480 120 520 100 M436 240 C430 300 424 360 416 420 M564 240 C572 300 580 360 588 420', SHADE, 12)
  + stroke('M470 108 C490 100 512 94 530 92', '#fff', 10))
  + stroke('M450 128 C470 112 500 100 530 90 M440 160 C452 140 470 126 500 112 M428 260 C424 310 418 360 414 400 M572 260 C576 310 582 360 586 400', '#cfcfcf', 2.5)
  + stroke('M452 142 C460 137 472 137 482 141 M518 141 C528 137 540 137 548 142', '#7d7d7d', 3.5) + '</g>'));

// ---- Clothes: a light gray base, darker folds and white sheen, tinted by the chosen color ----
const sheen = (d, w = 10) => stroke(d, '#fff', w);
const fold = (d, w = 16) => stroke(d, SHADE, w);
const bodice = 'M420 318 C440 308 470 322 500 330 C530 322 560 308 580 318 C590 360 572 400 556 440 C550 455 548 466 550 482 L450 482 C452 466 450 455 444 440 C428 400 410 360 420 318Z';
const bodiceShade = fold('M424 330 C430 380 444 430 452 480') + fold('M576 330 C570 380 556 430 548 480') + sheen('M470 340 C474 380 480 420 486 470', 8);
const straps = stroke('M436 314 C432 300 436 288 446 280 M564 314 C568 300 564 288 554 280', TINT_LINE, 8) + stroke('M436 314 C432 300 436 288 446 280 M564 314 C568 300 564 288 554 280', BASE, 4.5);
const sash = (y) => soft([`M446 ${y - 12} C480 ${y - 8} 520 ${y - 8} 554 ${y - 12} L556 ${y + 12} C520 ${y + 8} 480 ${y + 8} 444 ${y + 12}Z`], BASE, TINT_LINE, fold(`M446 ${y + 8} L556 ${y + 8}`, 8));

const tee = 'M468 272 C480 288 520 288 532 272 C556 278 578 288 590 300 C604 320 600 352 594 372 C584 410 562 436 556 470 C556 500 572 530 578 560 C560 572 530 576 500 576 C470 576 440 572 422 560 C428 530 444 500 444 470 C438 436 416 410 406 372 C400 352 396 320 410 300 C422 288 444 278 468 272Z';
const teeShapes = [tee, limb(grow(leftArm, 8, 0, 2)), limb(grow(rightArm, 8, 0, 2))];
const teeShade = fold('M410 330 C420 380 440 420 450 470 C446 510 430 540 428 570') + fold('M590 330 C580 380 560 420 550 470 C554 510 570 540 574 570')
  + fold(edge(leftArm.slice(0, 2), -1), 14) + fold('M470 520 C480 540 490 556 494 576', 6) + sheen('M470 300 C462 360 466 420 476 480');
// T-shirt over a denim skirt
const skirt = 'M436 540 C470 546 530 546 564 540 C576 590 590 640 602 690 Q550 706 500 706 Q450 706 398 690 C410 640 424 590 436 540Z';
parts.push(part('tshirt-under', soft([skirt], '#7593cc', '#4f6aa0', stroke('M420 600 C416 640 410 670 404 690 M580 600 C584 640 590 670 596 690', '#5c78b0', 18) + stroke('M480 560 C478 620 476 660 474 700', '#9bb3e0', 10))
  + stroke('M402 684 C460 696 540 696 598 684', '#e8c46a', 2, ' stroke-dasharray="6 5"') + stroke('M500 548 L500 640', '#4f6aa0', 2.5)));
parts.push(part('tshirt', soft(teeShapes, BASE, TINT_LINE, teeShade) + stroke('M468 272 C480 288 520 288 532 272', TINT_LINE, 4)));

// Gown: a fitted bodice and a long skirt that falls in soft folds
const gownSkirt = 'M450 478 L550 478 C560 560 610 700 660 860 C700 980 740 1100 770 1200 Q720 1222 680 1210 Q640 1232 590 1214 Q545 1236 500 1216 Q455 1236 410 1214 Q360 1232 320 1210 Q280 1222 232 1200 C262 1100 300 980 340 860 C390 700 440 560 450 478Z';
parts.push(part('gown', soft([gownSkirt], BASE, TINT_LINE,
  fold('M480 500 C470 700 440 960 410 1220', 26) + fold('M520 500 C540 700 570 960 590 1220', 26) + fold('M452 490 C400 700 330 960 250 1206', 30) + fold('M548 490 C620 700 690 960 760 1206', 34)
  + sheen('M500 520 C500 760 500 1000 500 1220', 18) + sheen('M466 520 C440 760 390 1000 330 1214', 12) + sheen('M534 520 C560 760 610 1000 680 1214', 12))
  + soft([bodice], BASE, TINT_LINE, bodiceShade) + sash(480)));
parts.push(part('gown-over', [[500, 400], [470, 600], [530, 700], [420, 860], [580, 900], [360, 1080], [500, 1000], [640, 1100], [450, 1160], [560, 1170], [480, 360], [600, 1010], [400, 980]]
  .map(([x, y], k) => path(twinkle(x, y, k % 3 ? 7 : 10), '#fff')).join('')));

// Party dress: a twirly skirt over a lacy petticoat, with a sash and bow
const partySkirt = 'M452 478 L548 478 C570 540 640 640 690 738 Q660 772 624 760 Q590 786 552 768 Q520 790 486 770 Q452 790 420 766 Q384 784 352 760 Q326 772 310 738 C360 640 430 540 452 478Z';
parts.push(part('party-under', path('M318 744 C380 790 620 790 682 744 L694 760 Q676 784 652 774 Q630 796 604 782 Q578 802 550 786 Q524 804 500 788 Q476 804 450 786 Q422 802 396 782 Q370 796 348 774 Q324 784 306 760Z', '#fffdf8', '#c9bfb0', 2.5)
  + [...Array(14)].map((_, k) => `<circle cx="${f(330 + k * 26)}" cy="${f(774 + 8 * Math.sin(k))}" r="3" fill="none" stroke="#d8cfc0" stroke-width="1.5"/>`).join('')));
parts.push(part('party', soft([partySkirt], BASE, TINT_LINE,
  fold('M470 490 C440 600 400 700 360 770', 22) + fold('M530 490 C560 600 600 700 640 770', 22) + fold('M500 500 C500 600 500 700 500 780', 14)
  + sheen('M484 500 C470 600 450 700 430 770', 10) + sheen('M516 500 C530 600 550 700 570 770', 10))
  + soft([bodice], BASE, TINT_LINE, bodiceShade) + straps));
parts.push(part('party-over', soft([`M446 468 C480 472 520 472 554 468 L556 492 C520 488 480 488 444 492Z`], '#fffdf8', '#c9bfb0')
  + path('M548 480 C572 456 596 462 590 480 C596 498 572 504 548 480Z', '#fffdf8', '#c9bfb0', 2.5) + path('M548 480 C534 456 510 462 514 480 C510 498 534 504 548 480Z', '#fffdf8', '#c9bfb0', 2.5)
  + path('M546 482 C552 506 560 524 566 530 L556 532 C550 516 546 500 546 482Z', '#fffdf8', '#c9bfb0', 2) + `<circle cx="548" cy="480" r="7" fill="#fffdf8" stroke="#c9bfb0" stroke-width="2.5"/>`
  + [[440, 570], [560, 600], [500, 680], [400, 710], [600, 720], [470, 380], [530, 420], [470, 640]].map(([x, y]) => path(twinkle(x, y, 7), '#fff')).join('')));

// Tutu: a leotard and puffy layers of tulle
const leotard = 'M420 318 C440 308 470 322 500 330 C530 322 560 308 580 318 C590 360 572 400 556 440 C550 460 548 470 550 480 C552 520 574 548 578 574 C560 600 530 612 500 618 C470 612 440 598 424 566 C428 540 448 510 450 480 C452 466 450 455 444 440 C428 400 410 360 420 318Z';
const tulle = (y, w, h) => { let d = `M${500 - w} ${y}`; const n = 10; for (let k = 0; k < n; k++) { const x0 = 500 - w + (2 * w * k) / n, x1 = 500 - w + (2 * w * (k + 1)) / n; d += ` Q${f((x0 + x1) / 2)} ${y + h} ${f(x1)} ${y}`; } return d + ` C${500 + w * 0.8} ${y - 60} ${500 - w * 0.8} ${y - 60} ${500 - w} ${y}Z`; };
parts.push(part('tutu', soft([leotard], BASE, TINT_LINE, bodiceShade + fold('M440 560 C460 600 480 612 500 618', 12)) + straps
  + [[618, 180, 34, SHADE], [600, 166, 32, '#e2e2e2'], [584, 146, 28, BASE]].map(([y, w, h, c]) => soft([tulle(y, w, h)], c, TINT_LINE, sheen(`M${500 - w * 0.7} ${y - 6} C${500 - w * 0.3} ${y - 24} ${500 + w * 0.3} ${y - 24} ${500 + w * 0.7} ${y - 6}`, 8))).join('')));
parts.push(part('tutu-over', [[400, 604], [450, 624], [520, 616], [580, 600], [612, 622], [470, 594], [540, 640]].map(([x, y]) => path(twinkle(x, y, 6), '#fff')).join('')));

// Overalls over a striped shirt, with rolled cuffs
const pantsL = limb(grow(leftLeg, 7)), pantsR = limb(grow(rightLeg, 7));
const hipPiece = 'M446 470 L554 470 C560 510 576 540 582 574 C564 602 530 616 500 618 C470 616 436 602 418 568 C426 540 440 510 446 470Z';
const stripes = (shapes) => { const id = 'c' + ids++; return `<clipPath id="${id}">${shapes.map((d) => `<path d="${d}"/>`).join('')}</clipPath><g clip-path="url(#${id})">${[300, 330, 360, 390, 420, 450].map((y) => stroke(`M380 ${y} C450 ${y + 6} 550 ${y + 6} 640 ${y - 4}`, '#f5b4c6', 8)).join('')}</g>`; };
parts.push(part('overalls-under', soft(teeShapes, '#fffdf8', '#c9bfb0', fold('M410 330 C420 380 440 420 450 470') + fold('M590 330 C580 380 560 420 550 470')).replace(new RegExp(SHADE, 'g'), '#e6dfd4')
  + stripes(teeShapes) + stroke('M468 272 C480 288 520 288 532 272', '#c9bfb0', 4)));
parts.push(part('overalls', soft([pantsL, pantsR, hipPiece], BASE, TINT_LINE,
  fold(edge(leftLeg, -1), 26) + fold(edge(rightLeg, -1), 26) + fold('M500 600 L500 660', 14) + sheen(edge(leftLeg, 0.45), 9) + sheen(edge(rightLeg, 0.45), 9)
  + fold('M440 860 C460 870 480 870 496 862 M516 866 C530 876 548 876 562 866', 6))
  + soft(['M460 1100 Q484 1094 508 1100 L508 1124 Q484 1130 460 1124Z', 'M542 1092 Q566 1086 590 1092 L591 1116 Q567 1122 543 1116Z'], '#e2e2e2', TINT_LINE)
  + soft(['M452 392 Q452 384 460 384 L540 384 Q548 384 548 392 L552 482 L448 482Z'], BASE, TINT_LINE, fold('M456 392 L456 480', 10) + sheen('M480 392 L478 470', 8))
  + path('M472 404 L528 404 L526 440 Q500 448 474 440Z', 'none', TINT_LINE, 3)
  + stroke('M444 300 C448 330 452 360 456 390 M556 300 C552 330 548 360 544 390', TINT_LINE, 16) + stroke('M444 300 C448 330 452 360 456 390 M556 300 C552 330 548 360 544 390', BASE, 11)
  + stroke('M440 540 Q450 560 470 556 M560 540 Q550 560 530 556', TINT_LINE, 3)));
parts.push(part('overalls-over', [[456, 394], [544, 394]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="7" fill="#f2c94c" stroke="#b8902a" stroke-width="2"/><circle cx="${x - 2}" cy="${y - 2}" r="2" fill="#fff"/>`).join('')));

// Pajamas: a loose top with long sleeves, comfy pants, and white stars
const pjTop = 'M466 272 C480 286 520 286 534 272 C556 278 578 288 590 300 C604 320 600 352 594 372 C584 410 566 436 560 470 C562 510 578 546 584 590 C556 604 530 608 500 608 C470 608 444 604 416 590 C422 546 438 510 440 470 C434 436 416 410 406 372 C400 352 396 320 410 300 C422 288 444 278 466 272Z';
const pjShapes = [pantsL, pantsR, hipPiece, limb(grow(leftArm, 7)), limb(grow(rightArm, 7)), pjTop];
parts.push(part('pajamas', soft(pjShapes, BASE, TINT_LINE,
  fold(edge(leftLeg, -1), 26) + fold(edge(rightLeg, -1), 26) + fold(edge(leftArm, -1), 18) + fold(edge(rightArm, -1), 18)
  + fold('M416 330 C426 400 444 460 446 520 C444 560 430 580 420 596') + fold('M584 330 C574 400 556 460 554 520 C556 560 570 580 580 596')
  + sheen(edge(leftLeg, 0.45), 9) + sheen(edge(rightLeg, 0.45), 9) + sheen('M470 300 C462 380 466 460 474 560'))
  + path('M466 272 C480 286 520 286 534 272 L542 282 C520 304 480 304 458 282Z', BASE, TINT_LINE, 3)
  + stroke('M500 296 L500 604', TINT_LINE, 3) + stroke('M388 572 Q400 580 414 574 M572 480 Q580 494 592 498 M462 1124 Q484 1132 506 1124 M546 1114 Q566 1122 588 1112', TINT_LINE, 3)));
const legStars = [leftLeg, rightLeg].flatMap((l) => [14, 26, 38, 50].map((i) => at(l, i)));
parts.push(part('pajamas-over', [[470, 340], [530, 410], [476, 500], [540, 550], [404, 420], [404, 520], [626, 410], ...legStars.map(([x, y]) => [x, y])]
  .map(([x, y]) => path(star(f(x), f(y), 9), '#fff')).join('')
  + [350, 420, 490].map((y) => `<circle cx="510" cy="${y}" r="4" fill="#fff" stroke="#aaa" stroke-width="1.5"/>`).join('')));

// ---- Shoes, in their own colors, drawn for a foot standing at (0, 0) and turned to fit each foot ----
const feet = (draw) => [leftFoot, rightFoot].map((foot, i) => {
  const [ax, ay] = foot[0], [tx, ty] = foot[2];
  const angle = f(Math.atan2(-(tx - ax), ty - ay) * 180 / Math.PI);
  return `<g transform="translate(${ax} ${ay}) rotate(${angle})">${draw(i ? 1 : -1)}</g>`;
}).join('');
parts.push(part('heels', feet((d) => path(`M${9 * d} 22 L${6 * d} 66 L${11 * d} 66 L${15 * d} 24Z`, '#c23a78', '#8f2556', 2.5)
  + soft(['M-14 20 C-15 9 15 9 14 20 C15 40 7 62 0 64 C-7 62 -15 40 -14 20Z'], '#ec5596', '#a82a64', stroke('M8 24 C9 40 6 54 2 62', '#c23a78', 8))
  + `<ellipse cx="${-5 * d}" cy="36" rx="2.5" ry="9" fill="#fff" opacity="0.55"/>`)));
parts.push(part('sneakers', feet((d) => soft(['M-19 44 C-21 8 21 8 19 44 C19 58 -19 58 -19 44Z'], '#f2846f', '#b8503e', stroke('M12 20 C14 34 14 44 12 52', '#d0624f', 8))
  + path('M-21 46 C-21 66 21 66 21 46 C10 53 -10 53 -21 46Z', '#fff', '#b9b0a4', 2.5) + stroke('M-8 24 L8 28 M-8 33 L8 37', '#fff', 3.5)
  + `<circle cx="${12 * d}" cy="40" r="3.5" fill="#fff" stroke="#b8503e" stroke-width="1.5"/>`)));
parts.push(part('boots', feet((d) => soft(['M-23 -150 C-10 -154 10 -154 23 -150 L20 32 C22 64 -22 64 -20 32Z'], '#a8754c', '#6e4a2c', stroke(`M${14 * d} -146 L${12 * d} 40`, '#87593a', 12) + stroke(`M${-10 * d} -140 L${-8 * d} 30`, '#c79a72', 6))
  + soft(['M-25 -156 C-10 -162 10 -162 25 -156 L24 -132 C10 -136 -10 -136 -24 -132Z'], '#f6ead8', '#c9b49a', stroke('M-24 -136 L24 -136', '#e0cfb4', 6))
  + path('M-22 52 C-22 70 22 70 22 52Z', '#5b3a26', '#3e2718', 2))));
parts.push(part('flats', feet(() => soft(['M-14 30 C-16 62 16 62 14 30 C8 38 -8 38 -14 30Z'], '#f7bccd', '#c97f96', stroke('M8 34 C10 46 8 56 4 60', '#e79ab1', 7))
  + path('M-7 38 C-12 30 -4 28 0 37 C4 28 12 30 7 38 C0 42 0 42 -7 38Z', '#e8789a', '#b85574', 1.5) + stroke('M-13 14 C-6 20 6 20 13 14', '#e8789a', 3))));
parts.push(part('sandals', feet(() => path('M-18 58 C-18 70 18 70 18 58Z', '#c98a4b', '#8c5a2a', 2)
  + stroke('M-13 32 L13 32 M-15 48 L15 48 M0 32 L0 48', '#e99a3c', 5.5) + `<circle cx="0" cy="32" r="4" fill="#f6d365" stroke="#b8902a" stroke-width="1.5"/>`)));

// ---- Hats, tilted with her head ----
const hat = (body) => `<g transform="${HEAD}">${body}</g>`;
const straw = '#f4dd94', strawLine = '#b9994a';
parts.push(part('sunHat', hat(soft(['M500 130 C380 130 326 110 336 88 C352 60 420 54 500 54 C580 54 648 60 664 88 C674 110 620 130 500 130Z'], straw, strawLine, stroke('M350 110 C420 126 580 126 650 110', '#d9bd6a', 16))
  + soft(['M436 98 C432 40 460 18 500 18 C540 18 568 40 564 98 C540 106 460 106 436 98Z'], straw, strawLine, stroke('M550 30 C562 50 564 80 560 98', '#d9bd6a', 16))
  + stroke('M370 92 C440 80 560 80 630 92 M460 40 C480 56 520 56 540 40', '#e3c876', 2.5))));
parts.push(part('sunHatBand', hat(soft(['M438 92 C437 84 438 78 440 72 C470 80 530 80 560 72 C562 78 563 84 562 92 C536 100 464 100 438 92Z', 'M548 86 C570 66 592 74 584 90 C592 106 570 108 548 86Z'], BASE, TINT_LINE, stroke('M440 92 L562 92', SHADE, 8)))));
parts.push(part('crown', hat(soft(['M444 100 L436 46 L466 72 L500 30 L534 72 L564 46 L556 100Z'], '#f6c945', '#b8902a', stroke('M444 96 L556 96', '#d9a52a', 14) + stroke('M452 60 L458 86', '#fff4c4', 6))
  + `<circle cx="500" cy="76" r="8" fill="#ec5596" stroke="#a82a64" stroke-width="2"/><circle cx="497" cy="73" r="2.5" fill="#fff"/>`
  + `<circle cx="468" cy="88" r="5" fill="#6fb8f0" stroke="#3f80b8" stroke-width="1.5"/><circle cx="532" cy="88" r="5" fill="#6fb8f0" stroke="#3f80b8" stroke-width="1.5"/>`
  + [[436, 46], [500, 30], [564, 46]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="5" fill="#fff4c4" stroke="#b8902a" stroke-width="1.5"/>`).join(''))));
parts.push(part('bow', hat(soft(['M556 96 C580 52 628 60 622 96 C628 132 580 140 556 96Z', 'M556 96 C532 52 496 66 500 96 C496 126 532 140 556 96Z'], '#ec5596', '#a82a64',
  stroke('M570 84 C590 74 606 80 610 92 M542 84 C526 76 514 82 512 94', '#c23a78', 10) + stroke('M584 112 C600 116 612 110 616 100', '#f59bc0', 6))
  + path('M546 86 Q556 82 566 86 L566 106 Q556 110 546 106Z', '#d4447f', '#a82a64', 2.5))));
parts.push(part('beanie', hat(soft(['M418 128 C412 60 450 28 500 28 C550 28 588 60 582 128Z'], BASE, TINT_LINE, stroke('M560 50 C576 80 580 110 578 128', SHADE, 18) + sheen('M450 60 C460 44 480 36 500 34', 8))
  + stroke('M442 122 C440 84 454 54 476 40 M500 122 L500 32 M558 122 C560 84 546 54 524 40', '#d6d6d6', 3))));
parts.push(part('beanie-over', hat(soft(['M410 110 C460 98 540 98 590 110 L592 138 C540 126 460 126 408 138Z'], '#fdfbf7', '#c9bfb0', stroke('M410 132 C460 120 540 120 592 132', '#e6dfd4', 8))
  + stroke('M430 112 L430 128 M455 106 L455 124 M480 104 L480 122 M505 104 L505 122 M530 104 L530 122 M555 106 L555 124 M578 110 L578 128', '#e3dccf', 2.5)
  + soft(['M500 2 C512 2 520 10 520 22 C520 34 512 42 500 42 C488 42 480 34 480 22 C480 10 488 2 500 2Z'], '#fdfbf7', '#c9bfb0', stroke('M506 8 C516 16 516 30 508 38', '#e6dfd4', 10)))));
const flower = (x, y, c, line) => [0, 1, 2, 3, 4].map((k) => { const a = k * 2 * Math.PI / 5; return `<circle cx="${f(x + 8.5 * Math.cos(a))}" cy="${f(y + 8.5 * Math.sin(a))}" r="7.5" fill="${c}" stroke="${line}" stroke-width="1.5"/>`; }).join('') + `<circle cx="${x}" cy="${y}" r="5" fill="#f6c945" stroke="#b8902a" stroke-width="1.2"/>`;
const petals = [['#f5a3bb', '#c86f88'], ['#f8d873', '#b8962e'], ['#c0aef2', '#8873c4'], ['#f8bd8a', '#c4834e']];
parts.push(part('flowers', hat(stroke('M424 140 C430 90 470 72 500 72 C530 72 570 90 576 140', '#6aa84f', 5)
  + [...Array(7)].map((_, k) => { const a = Math.PI * (1.08 + 0.84 * k / 6); return path(`M${f(500 + 82 * Math.cos(a))} ${f(130 + 66 * Math.sin(a))} q${-8 + 3 * k} -10 ${4} -14 q4 8 -4 14Z`, '#86c873', '#4f8a3c', 1.5); }).join('')
  + [...Array(7)].map((_, k) => { const a = Math.PI * (1.08 + 0.84 * k / 6); return flower(f(500 + 78 * Math.cos(a)), f(132 + 64 * Math.sin(a)), ...petals[k % 4]); }).join(''))));

// ---- Extras ----
parts.push(part('purse', stroke('M626 448 C618 488 640 498 662 498 C690 498 690 468 668 444', '#a33a6a', 5)
  + soft(['M620 496 Q660 488 700 496 L712 570 Q660 586 608 570Z'], '#ec5596', '#a82a64', stroke('M700 500 L712 570', '#c23a78', 22) + stroke('M630 504 L622 566', '#f59bc0', 8))
  + path('M614 496 Q660 486 706 496 L708 518 Q660 534 612 518Z', '#f27bb0', '#a82a64', 2.5) + `<circle cx="660" cy="524" r="6" fill="#f6c945" stroke="#b8902a" stroke-width="2"/>`));
parts.push(part('wand', stroke('M400 628 L340 520', '#b9994a', 9) + stroke('M400 628 L340 520', '#fff8e8', 5)
  + soft([star(334, 506, 30)], '#f6c945', '#b8902a', stroke('M334 480 L350 520', '#e0a92a', 12)) + path(star(330, 502, 9), '#fff4c4')
  + [[292, 470, 9], [378, 470, 7], [288, 540, 6]].map(([x, y, r]) => path(twinkle(x, y, r), '#fff', '#c9a84e', 1.5)).join('')));
parts.push(part('sunglasses', hat(path('M442 156 L496 156 C496 182 486 192 469 192 C450 192 442 180 442 156Z M504 156 L558 156 C558 180 550 192 531 192 C514 192 504 182 504 156Z', '#3a2a4a', '#1f1426', 3)
  + `<path d="M442 156 L496 156 L494 166 L444 166Z M504 156 L558 156 L556 166 L506 166Z" fill="#ec5596" opacity="0.85"/>`
  + stroke('M496 160 C500 156 500 156 504 160 M442 158 L428 152 M558 158 L572 152', '#1f1426', 4) + stroke('M452 168 L462 180 M514 168 L524 180', '#fff', 3, ' opacity="0.7"'))));
parts.push(part('necklace', [...Array(11)].map((_, k) => { const a = Math.PI * (0.08 + 0.84 * k / 10); const x = f(500 + 40 * Math.cos(a)), y = f(280 + 28 * Math.sin(a)); return `<circle cx="${x}" cy="${y}" r="6" fill="#fdf8ef" stroke="#c9bfb0" stroke-width="1.5"/><circle cx="${f(x - 2)}" cy="${f(y - 2)}" r="1.8" fill="#fff"/>`; }).join('')
  + path('M500 310 L512 324 L500 342 L488 324Z', '#ec5596', '#a82a64', 2) + path('M500 314 L506 324 L500 330Z', '#f9b6d0')));

const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1300">
  <!-- The Dress Up doll, written by doll.js (edit that, not this). One layer per part, rendered one at a time by render.js. -->
  <defs><filter id="blur" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="7"/></filter></defs>
${parts.join('\n')}
</svg>
`;
fs.writeFileSync(process.argv[2], svg);
console.log(parts.length, 'parts', svg.length, 'bytes');
