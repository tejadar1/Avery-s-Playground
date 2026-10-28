// Writes Art/doll.svg, the Dress Up doll: one <g class="part"> per layer, each rendered to its own image by render.js.
// Tinted parts are drawn in white and grays (the app multiplies them by skin, hair, eye or clothes color); "-under"
// and "-over" parts keep their own colors and go below and above it. Run: node Art/doll.js Art/doll.svg
const fs = require('fs');
const O = '#4A2C2A', W = 6;
const SH = '#d8d8d8', SH2 = '#bdbdbd', SKSH = '#ecd5cb';
const f = (n) => +n.toFixed(1);

function smooth(pts, per = 12) {
  // Catmull-Rom through [x, y, r]
  const out = [];
  const p = [pts[0], ...pts, pts[pts.length - 1]];
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
// A tapered limb through [x, y, radius] points, with round ends.
function limb(pts) {
  const s = smooth(pts), n = normals(s);
  const L = s.map((p, i) => [p[0] + n[i][0] * p[2], p[1] + n[i][1] * p[2]]);
  const R = s.map((p, i) => [p[0] - n[i][0] * p[2], p[1] - n[i][1] * p[2]]);
  const e = s[s.length - 1][2], b = s[0][2];
  return `M${L.map((q) => f(q[0]) + ' ' + f(q[1])).join(' L')} A${f(e)} ${f(e)} 0 0 0 ${R.slice(-1).map((q) => f(q[0]) + ' ' + f(q[1]))} L${R.reverse().map((q) => f(q[0]) + ' ' + f(q[1])).join(' L')} A${f(b)} ${f(b)} 0 0 0 ${f(L[0][0])} ${f(L[0][1])}Z`;
}
// One side of a limb, from `a` to `b` times its radius (negative is the other side): the shadow.
function side(pts, a, b) {
  const s = smooth(pts), n = normals(s);
  const A = s.map((p, i) => [p[0] + n[i][0] * p[2] * a, p[1] + n[i][1] * p[2] * a]);
  const B = s.map((p, i) => [p[0] + n[i][0] * p[2] * b, p[1] + n[i][1] * p[2] * b]).reverse();
  return 'M' + [...A, ...B].map((q) => f(q[0]) + ' ' + f(q[1])).join(' L') + 'Z';
}
const mirror = (pts) => pts.map(([x, y, r]) => [1000 - x, y, r]);
// Outline everything first, then fill on top, so overlapping shapes share one outline.
const union = (paths, fill, extra = '') => `<g stroke="${O}" stroke-width="${2 * W}" stroke-linejoin="round" fill="${O}">${paths.map((d) => `<path d="${d}"/>`).join('')}</g><g fill="${fill}">${paths.map((d) => `<path d="${d}"/>`).join('')}</g>${extra}`;
const shape = (d, fill, sw = W) => `<path d="${d}" fill="${fill}" stroke="${O}" stroke-width="${sw}" stroke-linejoin="round" stroke-linecap="round"/>`;
const line = (d, color = O, sw = W * 0.7) => `<path d="${d}" fill="none" stroke="${color}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round"/>`;
const part = (id, body) => `<g id="${id}" class="part">${body}</g>`;

// ---- The pose ----
const leftArm = [[421, 318, 22], [404, 390, 18], [397, 455, 15], [386, 520, 13], [379, 585, 10.5]];
const rightArm = [[579, 318, 22], [618, 375, 18], [652, 432, 15], [622, 470, 13], [588, 500, 11]];
const leftHand = [[379, 588, 11.5], [375, 612, 12.5], [372, 640, 9]];
const leftThumb = [[386, 600, 6], [391, 622, 5]];
const rightHand = [[590, 500, 11.5], [567, 512, 11], [550, 520, 8.5]];
const leftLeg = [[462, 575, 38], [466, 700, 31], [471, 855, 21], [473, 950, 23], [476, 1080, 16], [479, 1150, 12.5]];
const rightLeg = mirror(leftLeg);
const leftFoot = [[480, 1145, 12], [476, 1180, 13], [470, 1205, 10]];
const rightFoot = mirror(leftFoot);
const torso = 'M480 282 C458 292 430 294 414 304 C398 316 404 360 418 392 C432 424 452 450 455 472 C452 500 430 530 427 566 C428 594 460 612 500 612 C540 612 572 594 573 566 C570 530 548 500 545 472 C548 450 568 424 582 392 C596 360 602 316 586 304 C570 294 542 292 520 282Z';
const neck = 'M479 210 L479 292 C490 300 510 300 521 292 L521 210Z';
const head = 'M500 84 C548 84 572 118 571 160 C570 200 548 236 500 250 C452 236 430 200 429 160 C428 118 452 84 500 84Z';

const parts = [];

// Hair behind, long and wavy, tinted by hair color; its shine stays white.
const hairBack = 'M500 72 C430 70 382 120 384 200 C386 260 368 300 360 360 C350 430 356 500 374 545 C386 560 402 552 410 540 C424 556 444 560 456 546 C470 560 490 560 500 548 C510 560 530 560 544 546 C556 560 576 556 590 540 C598 552 614 560 626 545 C644 500 650 430 640 360 C632 300 614 260 616 200 C618 120 570 70 500 72Z';
parts.push(part('hairBack', shape(hairBack, '#f4f4f4')
  + `<path d="M392 230 C380 320 370 420 384 530 L410 540 C396 440 396 330 410 240Z M608 240 C622 330 624 440 590 540 L616 530 C630 420 620 320 608 230Z" fill="${SH}"/>`
  + line('M410 260 C400 340 396 430 412 520 M590 260 C600 340 604 430 588 520 M430 300 C424 380 428 460 440 530 M570 300 C576 380 572 460 560 530', SH2, 4)));

// Skin: arms, legs, hands, feet and body under one outline, then the head on top.
const bodyShapes = [torso, neck, limb(leftArm), limb(rightArm), limb(leftHand), limb(leftThumb), limb(rightHand), limb(leftLeg), limb(rightLeg), limb(leftFoot), limb(rightFoot)];
const bodyShade = [side(leftArm, -0.2, -1), side(rightArm, -0.2, -1), side(leftLeg, -0.25, -1), side(rightLeg, -0.25, -1)]
  .map((d) => `<path d="${d}" fill="${SKSH}"/>`).join('')
  + `<path d="M420 330 C430 370 440 400 452 440 L455 472 C440 440 420 400 414 360Z M580 330 C570 370 560 400 548 440 L545 472 C560 440 580 400 586 360Z" fill="${SKSH}"/>`
  // knees, collarbones, the line between the legs, fingers
  + line('M466 862 C472 868 480 868 484 862 M516 862 C520 868 528 868 534 862', SH2, 3.5)
  + line('M455 300 C468 306 482 304 492 300 M508 300 C518 304 532 306 545 300', SKSH, 4)
  + line('M500 612 L500 640', O, 4)
  + line('M368 628 L368 642 M375 630 L375 645', SH2, 3)
  + `<path d="M479 238 C490 262 510 262 521 238 L521 262 C510 274 490 274 479 262Z" fill="${SKSH}"/>`;
parts.push(part('body', union(bodyShapes, '#fff', bodyShade)
  + shape(head, '#fff')
  + `<path d="M440 200 C452 232 476 246 500 250 C470 236 452 214 446 186Z" fill="${SKSH}" opacity="0.8"/>`
  + `<path d="M502 178 C504 190 506 198 507 202" fill="none" stroke="#e3c3b8" stroke-width="3" stroke-linecap="round"/><path d="M492 204 C496 210 504 210 508 204" fill="none" stroke="#b98d80" stroke-width="3.5" stroke-linecap="round"/>`));

// Eyes: whites under, the iris tinted by eye color, then lashes, lips and blush on top.
const eye = (x, d) => `M${x - 19 * d} 168 C${x - 10 * d} 155 ${x + 8 * d} 153 ${x + 19 * d} 163 C${x + 10 * d} 176 ${x - 8 * d} 178 ${x - 19 * d} 168Z`;
parts.push(part('eyes-under', [[472, -1], [528, 1]].map(([x, d]) => `<path d="${eye(x, d)}" fill="#fff"/>`).join('')));
parts.push(part('eyes', `<defs><clipPath id="eyeClip"><path d="${eye(472, -1)}"/><path d="${eye(528, 1)}"/></clipPath><radialGradient id="iris"><stop offset="0.45" stop-color="#fff"/><stop offset="1" stop-color="#9a9a9a"/></radialGradient></defs>`
  + `<g clip-path="url(#eyeClip)">${[471, 527].map((x) => `<circle cx="${x}" cy="166" r="9.5" fill="url(#iris)" stroke="${O}" stroke-width="2"/>`).join('')}</g>`));
parts.push(part('eyes-over', `<defs><radialGradient id="blush"><stop offset="0" stop-color="#f08aa0" stop-opacity="0.55"/><stop offset="1" stop-color="#f08aa0" stop-opacity="0"/></radialGradient>
  <linearGradient id="lips" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e2557a"/><stop offset="1" stop-color="#c63c64"/></linearGradient></defs>`
  + [471, 527].map((x) => `<circle cx="${x}" cy="166" r="4.5" fill="#2a1a1a"/><circle cx="${x + 3}" cy="162.5" r="2.6" fill="#fff"/><circle cx="${x - 3}" cy="169" r="1.2" fill="#fff" opacity="0.8"/>`).join('')
  + [[472, -1], [528, 1]].map(([x, d]) => `<path d="M${x - 19 * d} 168 C${x - 10 * d} 155 ${x + 8 * d} 153 ${x + 19 * d} 163" fill="none" stroke="${O}" stroke-width="4.5" stroke-linecap="round"/>`
    + line(`M${x + 19 * d} 163 L${x + 27 * d} 157 M${x + 15 * d} 159 L${x + 22 * d} 151 M${x + 10 * d} 157 L${x + 15 * d} 149`, O, 2.6)
    + line(`M${x - 17 * d} 171 C${x - 6 * d} 178 ${x + 8 * d} 176 ${x + 17 * d} 167`, '#c9a59a', 2)
    + `<path d="M${x - 20 * d} 160 C${x - 8 * d} 145 ${x + 10 * d} 145 ${x + 20 * d} 156" fill="none" stroke="#c8a2e0" stroke-width="5" stroke-linecap="round" opacity="0.55"/>`).join('')
  + `<ellipse cx="452" cy="196" rx="17" ry="10" fill="url(#blush)"/><ellipse cx="548" cy="196" rx="17" ry="10" fill="url(#blush)"/>`
  + `<path d="M482 218 C488 212 495 212 500 215 C505 212 512 212 518 218 C510 220 490 220 482 218Z" fill="url(#lips)" stroke="#9c2f4f" stroke-width="1.5"/>`
  + `<path d="M482 218 C490 231 510 231 518 218 C510 221 490 221 482 218Z" fill="url(#lips)" stroke="#9c2f4f" stroke-width="1.5"/>`
  + `<ellipse cx="503" cy="224" rx="6" ry="2" fill="#fff" opacity="0.6"/>`));

// Hair in front: a side part with bangs swept across, locks down past her shoulders, and the brows.
const bangs = 'M432 205 C418 140 440 82 500 76 C562 72 590 120 576 190 C570 160 560 130 545 116 C520 132 480 140 450 132 C440 150 436 178 432 205Z';
const lockL = 'M434 150 C416 220 424 290 408 350 C402 372 400 390 404 402 C424 370 446 300 446 220Z';
const lockR = 'M566 150 C584 220 576 290 592 350 C598 372 600 390 596 402 C576 370 554 300 554 220Z';
parts.push(part('hairFront', union([bangs, lockL, lockR], '#f4f4f4')
  + line('M455 95 C480 100 510 120 545 116 M470 88 C500 92 530 104 560 110', SH2, 3.5)
  + line('M434 230 C428 290 420 340 410 380 M566 230 C572 290 580 340 590 380', SH2, 3.5)
  + line('M454 144 C462 139 474 139 484 143 M516 143 C526 139 538 139 546 144', '#8a8a8a', 4.5)));
parts.push(part('hairFront-over', line('M458 96 C478 86 506 84 530 90', 'rgba(255,255,255,0.4)', 7)));

// ---- Clothes, tinted by the chosen color ----
const T = '#fff';
const sleeve = (arm, until) => limb(arm.slice(0, until).map(([x, y, r]) => [x, y, r + 4]));
const shortSleeveL = 'M414 304 C398 316 394 360 400 392 L436 388 C440 350 436 320 430 300Z';
const shortSleeveR = 'M586 304 C604 318 620 352 628 380 L594 396 C584 362 574 330 570 300Z';
const top = (neckline) => `M${neckline} C432 298 418 300 414 304 C398 316 404 360 418 392 C432 424 452 450 455 472 C452 500 432 530 428 566 L572 566 C568 530 548 500 545 472 C548 450 568 424 582 392 C596 360 602 316 586 304 C582 300 568 298`;
const tee = 'M470 290 C480 304 520 304 530 290 C548 292 570 296 586 304 C602 316 598 360 582 392 C568 424 548 450 545 472 C548 500 568 530 574 572 C540 584 460 584 426 572 C432 530 452 500 455 472 C452 450 432 424 418 392 C402 360 398 316 414 304 C430 296 452 292 470 290Z';
// T-shirt and a denim skirt
parts.push(part('tshirt-under', shape('M432 548 L568 548 L596 690 C540 704 460 704 404 690Z', '#6f8fc8')
  + line('M500 552 L500 690 M420 680 C470 690 530 690 580 680', '#e9c46a', 2.5) + `<path d="M500 552 L500 600 L540 600 L540 552Z" fill="#5b7bb4" stroke="${O}" stroke-width="3"/>`));
parts.push(part('tshirt', shape(tee, T) + shape(shortSleeveL, T) + shape(shortSleeveR, T)
  + `<path d="M418 392 C432 424 452 450 455 472 C452 500 432 530 426 572 C440 576 450 578 460 580 C462 520 470 470 446 420Z" fill="${SH}"/>`
  + line('M470 290 C480 304 520 304 530 290', O, 4) + line('M404 384 L434 380 M596 390 L626 376', SH2, 3)));

// Gown: fitted bodice and a long, full skirt in soft folds
const gownSkirt = 'M455 466 L545 466 C560 560 640 800 760 1196 C690 1222 600 1232 500 1232 C400 1232 310 1222 240 1196 C360 800 440 560 455 466Z';
const bodice = 'M430 312 C452 300 470 312 500 318 C530 312 548 300 570 312 C576 350 560 420 548 470 L452 470 C440 420 424 350 430 312Z';
parts.push(part('gown', shape(gownSkirt, T)
  + `<path d="M500 480 C520 700 560 960 610 1228 L680 1220 C620 960 560 700 520 480Z M480 480 C450 700 400 960 330 1220 L290 1210 C380 960 440 700 470 480Z" fill="${SH}"/>`
  + line('M500 600 C505 800 520 1000 540 1226 M470 620 C450 820 420 1000 400 1228 M530 600 C560 800 610 1000 660 1222', SH2, 3.5)
  + shape(bodice, T) + line('M416 300 C420 306 426 310 430 312 M584 300 C580 306 574 310 570 312', O, 4)
  + `<path d="M452 470 C440 420 424 350 430 312 C438 330 446 400 466 470Z" fill="${SH}"/>` + shape('M448 462 L552 462 L550 480 L450 480Z', T, 4)));
parts.push(part('gown-over', [[500, 420], [470, 600], [530, 700], [420, 860], [580, 900], [360, 1080], [500, 1000], [640, 1100], [450, 1160], [560, 1180], [490, 350]]
  .map(([x, y]) => `<path d="M${x} ${y - 9} L${x + 2.5} ${y - 2.5} L${x + 9} ${y} L${x + 2.5} ${y + 2.5} L${x} ${y + 9} L${x - 2.5} ${y + 2.5} L${x - 9} ${y} L${x - 2.5} ${y - 2.5}Z" fill="#fff" opacity="0.9"/>`).join('')));

// Party dress: sleeveless with a twirly skirt, a white sash with a bow
const partySkirt = 'M452 470 L548 470 C570 530 640 640 682 740 C640 760 570 772 500 772 C430 772 360 760 318 740 C360 640 430 530 452 470Z';
parts.push(part('party-under', `<path d="M320 740 C360 758 430 772 500 772 C570 772 640 758 680 740 L690 756 C640 780 570 790 500 790 C430 790 360 780 310 756Z" fill="#fff" stroke="${O}" stroke-width="4"/>`
  + `<path d="M314 748 Q330 770 346 756 Q362 776 380 762 Q398 782 416 768 Q434 786 452 772 Q470 790 490 776 Q510 792 528 776 Q546 790 566 772 Q584 786 602 768 Q620 782 638 762 Q656 776 672 756 Q688 770 690 752" fill="none" stroke="${O}" stroke-width="3"/>`));
parts.push(part('party', shape(partySkirt, T)
  + `<path d="M470 480 C450 560 400 660 360 752 L400 764 C430 660 470 560 485 480Z M520 480 C540 560 590 660 630 762 L660 750 C610 660 560 560 535 480Z" fill="${SH}"/>`
  + line('M500 490 L500 770 M480 500 C460 600 440 700 430 768 M520 500 C540 600 560 700 570 768', SH2, 3)
  + shape(bodice, T) + line('M436 312 C430 300 432 290 440 282 M564 312 C570 300 568 290 560 282', O, 7)));
parts.push(part('party-over', shape('M446 458 L554 458 L552 486 L448 486Z', '#fff', 4)
  + shape('M548 472 C570 452 590 456 586 474 C590 492 570 494 548 472Z', '#fff', 4) + shape('M548 472 C564 500 560 520 548 526 C540 510 542 490 548 472Z', '#fff', 3.5)
  + `<circle cx="548" cy="472" r="8" fill="#fff" stroke="${O}" stroke-width="4"/>`
  + [[440, 560], [560, 600], [500, 680], [400, 700], [600, 720], [470, 380], [530, 420]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="4.5" fill="#fff" opacity="0.9"/>`).join('')));

// Tutu: a leotard and layers of puffy tulle
const leotard = 'M430 312 C452 300 470 312 500 318 C530 312 548 300 570 312 C576 350 560 420 548 470 C552 510 568 540 572 566 C560 590 530 608 500 618 C470 608 440 590 428 566 C432 540 448 510 452 470 C440 420 424 350 430 312Z';
const tulle = (y, w, h) => { let d = `M${500 - w} ${y}`; const n = 9; for (let k = 0; k < n; k++) { const x0 = 500 - w + (2 * w * k) / n, x1 = 500 - w + (2 * w * (k + 1)) / n; d += ` Q${f((x0 + x1) / 2)} ${y + h} ${f(x1)} ${y}`; } return d + ` C${500 + w * 0.7} ${y - 70} ${500 - w * 0.7} ${y - 70} ${500 - w} ${y}Z`; };
parts.push(part('tutu', shape(leotard, T) + line('M436 312 C430 300 432 290 440 282 M564 312 C570 300 568 290 560 282', O, 7)
  + `<path d="M452 470 C440 420 424 350 430 312 C438 330 446 400 466 470Z" fill="${SH}"/>`
  + shape(tulle(610, 175, 40), SH) + shape(tulle(596, 160, 36), T) + shape(tulle(582, 140, 30), T)
  + line('M380 600 L370 630 M420 604 L414 640 M580 604 L586 640 M620 600 L630 630', SH2, 3)));
parts.push(part('tutu-over', [[400, 600], [450, 620], [520, 612], [580, 598], [610, 620], [470, 590]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="3.5" fill="#fff"/>`).join('')));

// Overalls over a white shirt
parts.push(part('overalls-under', shape(tee, '#fdfbf7') + shape(shortSleeveL, '#fdfbf7') + shape(shortSleeveR, '#fdfbf7')
  + line('M470 290 C480 304 520 304 530 290', O, 4) + line('M420 330 L580 330 M416 360 L584 360 M424 390 L576 390', '#f3b8c8', 6)));
const pants = (leg) => limb(leg.slice(0, 6).map(([x, y, r], i) => [x, y, r + (i < 2 ? 3 : 6)]));
parts.push(part('overalls', union([pants(leftLeg), pants(rightLeg), 'M428 470 L572 470 C574 520 576 548 578 580 C540 600 460 600 422 580 C424 548 426 520 428 470Z'], T,
  `<path d="${side(leftLeg, -0.2, -1.2)}" fill="${SH}"/><path d="${side(rightLeg, -0.2, -1.2)}" fill="${SH}"/>`)
  + shape('M446 382 L554 382 L556 476 L444 476Z', T) + shape('M466 400 L534 400 L532 440 L468 440Z', T, 3.5)
  + shape('M440 300 L456 300 L462 390 L448 390Z', T, 4) + shape('M560 300 L544 300 L538 390 L552 390Z', T, 4)
  + line('M500 600 L500 640', SH2, 3) + line('M448 476 L552 476', O, 4)));
parts.push(part('overalls-over', `<circle cx="455" cy="392" r="7" fill="#f2c94c" stroke="${O}" stroke-width="3"/><circle cx="545" cy="392" r="7" fill="#f2c94c" stroke="${O}" stroke-width="3"/>`));

// Pajamas: long sleeves and pants, with white stars
const pjTop = 'M466 288 C480 300 520 300 534 288 C552 292 572 296 586 304 C604 318 600 360 584 392 C570 424 552 450 550 472 C552 510 570 540 576 590 C540 604 460 604 424 590 C430 540 448 510 450 472 C448 450 430 424 416 392 C400 360 396 318 414 304 C428 296 448 292 466 288Z';
parts.push(part('pajamas', union([pants(leftLeg), pants(rightLeg), sleeve(leftArm, 5), sleeve(rightArm, 5)], T,
  `<path d="${side(leftLeg, -0.2, -1.2)}" fill="${SH}"/><path d="${side(rightLeg, -0.2, -1.2)}" fill="${SH}"/><path d="${side(leftArm, -0.2, -1.2)}" fill="${SH}"/>`)
  + shape(pjTop, T) + `<path d="M424 590 C440 560 450 520 452 480 C460 520 466 560 470 600Z" fill="${SH}"/>`
  + shape('M466 288 C480 300 520 300 534 288 L540 296 C520 316 480 316 460 296Z', T, 4)
  + line('M500 310 L500 590', O, 3.5) + line('M372 575 L392 580 M584 498 L600 488', O, 3.5)));
const star = (x, y, r) => { let d = ''; for (let k = 0; k < 10; k++) { const a = -Math.PI / 2 + k * Math.PI / 5, rr = k % 2 ? r * 0.45 : r; d += (k ? 'L' : 'M') + f(x + rr * Math.cos(a)) + ' ' + f(y + rr * Math.sin(a)); } return d + 'Z'; };
parts.push(part('pajamas-over', [[470, 360], [530, 420], [478, 500], [536, 540], [404, 420], [400, 520], [628, 420], [462, 680], [476, 820], [470, 980], [530, 740], [526, 900], [530, 1060], [466, 1100]]
  .map(([x, y]) => `<path d="${star(x, y, 9)}" fill="#fff" opacity="0.95"/>`).join('') + [500, 360, 420, 480].slice(1).map((y) => `<circle cx="508" cy="${y}" r="4" fill="#fff" stroke="${O}" stroke-width="2"/>`).join('')));

// ---- Shoes (their own colors), seen from the front ----
const feet = (fn) => [leftFoot, rightFoot].map((ft, i) => fn(ft, i ? 1 : -1)).join('');
const hot = '#e8478f', hotSh = '#c22f72';
parts.push(part('heels', feet(([, , [x, y]], d) => shape(`M${x + 8 * d} 1170 L${x + 4 * d} 1212 L${x + 9 * d} 1212 L${x + 14 * d} 1172Z`, hotSh, 4)
  + shape(`M${x - 13} 1170 C${x - 14} 1160 ${x + 14} 1160 ${x + 13} 1170 C${x + 14} 1190 ${x + 6} 1212 ${x} 1214 C${x - 6} 1212 ${x - 14} 1190 ${x - 13} 1170Z`, hot)
  + `<ellipse cx="${x - 4 * d}" cy="1186" rx="3" ry="8" fill="#fff" opacity="0.5"/>`)));
parts.push(part('sneakers', feet(([, , [x]], d) => shape(`M${x - 20} 1196 C${x - 22} 1160 ${x + 22} 1160 ${x + 20} 1196 C${x + 20} 1212 ${x - 20} 1212 ${x - 20} 1196Z`, '#f07f6b')
  + shape(`M${x - 22} 1198 C${x - 22} 1220 ${x + 22} 1220 ${x + 22} 1198 C${x + 10} 1204 ${x - 10} 1204 ${x - 22} 1198Z`, '#fff', 4)
  + line(`M${x - 8} 1172 L${x + 8} 1176 M${x - 8} 1180 L${x + 8} 1184`, '#fff', 3.5) + `<circle cx="${x + 12 * d}" cy="1188" r="4" fill="#fff" stroke="${O}" stroke-width="2"/>`)));
const boot = (ft, d) => { const x = ft[2][0]; const sh = '#7d5236', b = '#9c6b45'; return shape(`M${x - 22} 1000 L${x + 22} 1000 L${x + 20} 1180 C${x + 22} 1212 ${x - 22} 1212 ${x - 20} 1180Z`, b)
  + `<path d="M${x + 8 * d} 1004 L${x + 20 * d} 1004 L${x + 18 * d} 1182 L${x + 8 * d} 1190Z" fill="${sh}"/>` + shape(`M${x - 24} 994 L${x + 24} 994 L${x + 22} 1016 L${x - 22} 1016Z`, '#f6ead8', 4)
  + shape(`M${x - 22} 1200 C${x - 22} 1218 ${x + 22} 1218 ${x + 22} 1200Z`, '#5b3a26', 4); };
parts.push(part('boots', feet(boot)));
parts.push(part('flats', feet(([, , [x]], d) => shape(`M${x - 14} 1180 C${x - 16} 1210 ${x + 16} 1210 ${x + 14} 1180 C${x + 8} 1188 ${x - 8} 1188 ${x - 14} 1180Z`, '#f6b5c8')
  + shape(`M${x - 7} 1188 C${x - 12} 1180 ${x - 4} 1178 ${x} 1188 C${x + 4} 1178 ${x + 12} 1180 ${x + 7} 1188 C${x} 1192 ${x} 1192 ${x - 7} 1188Z`, '#e8789a', 2.5)
  + line(`M${x - 13} 1162 C${x - 6} 1168 ${x + 6} 1168 ${x + 13} 1162`, '#e8789a', 3.5))));
parts.push(part('sandals', feet(([, , [x]]) => shape(`M${x - 18} 1206 C${x - 18} 1218 ${x + 18} 1218 ${x + 18} 1206Z`, '#c98a4b', 4)
  + line(`M${x - 13} 1180 L${x + 13} 1180 M${x - 15} 1196 L${x + 15} 1196 M${x} 1180 L${x} 1196`, '#f0a040', 5.5) + `<circle cx="${x}" cy="1180" r="4.5" fill="#f6d365" stroke="${O}" stroke-width="2"/>`)));

// ---- Hats ----
parts.push(part('sunHat', `<path d="M500 128 C380 128 330 108 340 88 C356 62 420 56 500 56 C580 56 644 62 660 88 C670 108 620 128 500 128Z" fill="#f6e3a0" stroke="${O}" stroke-width="${W}"/>`
  + `<path d="M436 96 C432 40 460 18 500 18 C540 18 568 40 564 96 C540 104 460 104 436 96Z" fill="#f6e3a0" stroke="${O}" stroke-width="${W}"/>`
  + line('M360 96 C420 116 580 116 640 96 M380 80 C440 70 560 70 620 80 M460 40 C480 60 520 60 540 40', '#d9bf6a', 3)));
parts.push(part('sunHatBand', `<path d="M438 92 C437 84 438 78 440 72 C470 80 530 80 560 72 C562 78 563 84 562 92 C536 100 464 100 438 92Z" fill="#fff" stroke="${O}" stroke-width="4"/>`
  + `<path d="M548 86 C570 66 592 74 584 90 C592 106 570 108 548 86Z" fill="${SH}" stroke="${O}" stroke-width="4"/>`));
const crownPts = 'M444 98 L436 46 L466 72 L500 30 L534 72 L564 46 L556 98Z';
parts.push(part('crown', `<path d="${crownPts}" fill="#f6c945" stroke="${O}" stroke-width="${W}" stroke-linejoin="round"/>` + `<path d="M444 98 L556 98 L554 86 L446 86Z" fill="#e0a92a"/>`
  + `<circle cx="500" cy="74" r="8" fill="#e8478f" stroke="${O}" stroke-width="3"/><circle cx="468" cy="86" r="5" fill="#6fb8f0" stroke="${O}" stroke-width="2.5"/><circle cx="532" cy="86" r="5" fill="#6fb8f0" stroke="${O}" stroke-width="2.5"/>`
  + [[436, 46], [500, 30], [564, 46]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="5" fill="#fff4c4" stroke="${O}" stroke-width="2.5"/>`).join('') + line('M450 62 L456 80', '#fff', 4)));
parts.push(part('bow', shape('M556 96 C580 52 628 60 622 96 C628 132 580 140 556 96Z', hot) + shape('M556 96 C532 52 496 66 500 96 C496 126 532 140 556 96Z', hot)
  + line('M570 86 C590 76 606 80 610 90 M542 86 C526 78 514 82 512 92', hotSh, 4) + shape('M546 86 L566 86 L566 106 L546 106Z', hotSh, 4)));
parts.push(part('beanie', `<path d="M418 128 C412 60 450 28 500 28 C550 28 588 60 582 128Z" fill="#fff" stroke="${O}" stroke-width="${W}"/>`
  + line('M440 120 C440 80 456 50 478 38 M500 120 L500 30 M560 120 C560 80 544 50 522 38', SH2, 4)));
parts.push(part('beanie-over', shape('M410 110 C460 98 540 98 590 110 L592 138 C540 126 460 126 408 138Z', '#fdfbf7') + line('M430 112 L430 128 M455 106 L455 124 M480 104 L480 122 M505 104 L505 122 M530 104 L530 122 M555 106 L555 124 M578 110 L578 128', '#ddd', 3)
  + `<circle cx="500" cy="22" r="20" fill="#fdfbf7" stroke="${O}" stroke-width="${W}"/>` + line('M488 16 L496 26 M504 12 L508 24 M492 30 L508 30', '#ddd', 3)));
const flower = (x, y, c) => [0, 1, 2, 3, 4].map((k) => { const a = k * 2 * Math.PI / 5; return `<circle cx="${f(x + 9 * Math.cos(a))}" cy="${f(y + 9 * Math.sin(a))}" r="8" fill="${c}" stroke="${O}" stroke-width="2.5"/>`; }).join('') + `<circle cx="${x}" cy="${y}" r="5.5" fill="#f6c945" stroke="${O}" stroke-width="2"/>`;
const petals = ['#f39ab4', '#f6d365', '#b9a2ef', '#f7b27a'];
parts.push(part('flowers', line('M424 140 C430 90 470 72 500 72 C530 72 570 90 576 140', '#6aa84f', 6)
  + [...Array(7)].map((_, k) => { const a = Math.PI * (1.08 + 0.84 * k / 6); return `<path d="M${f(500 + 82 * Math.cos(a))} ${f(130 + 66 * Math.sin(a))} l${-10 + 4 * k} -6 l6 12Z" fill="#7cc36a" stroke="${O}" stroke-width="2"/>`; }).join('')
  + [...Array(7)].map((_, k) => { const a = Math.PI * (1.08 + 0.84 * k / 6); return flower(f(500 + 78 * Math.cos(a)), f(132 + 64 * Math.sin(a)), petals[k % 4]); }).join('')));

// ---- Extras ----
parts.push(part('purse', line('M628 450 C620 490 640 500 662 500 C690 500 690 470 668 446', '#a33a6a', 6)
  + shape('M620 498 L700 498 L712 572 C690 584 630 584 608 572Z', '#e8478f') + `<path d="M676 500 L700 498 L712 572 C704 576 692 578 684 580Z" fill="${hotSh}"/>`
  + shape('M614 498 L706 498 L708 520 C680 534 640 534 612 520Z', '#f27bb0', 4) + `<circle cx="660" cy="526" r="7" fill="#f6c945" stroke="${O}" stroke-width="3"/>`));
parts.push(part('wand', line('M372 628 L310 520', O, 13) + line('M372 628 L310 520', '#fff8e8', 7)
  + `<path d="${star(304, 506, 30)}" fill="#f6c945" stroke="${O}" stroke-width="${W}" stroke-linejoin="round"/>` + `<path d="${star(300, 502, 10)}" fill="#fff4c4"/>`
  + [[262, 470, 7], [348, 470, 6], [258, 540, 5]].map(([x, y, r]) => `<path d="M${x} ${y - r * 1.6} L${x + r * 0.4} ${y - r * 0.4} L${x + r * 1.6} ${y} L${x + r * 0.4} ${y + r * 0.4} L${x} ${y + r * 1.6} L${x - r * 0.4} ${y + r * 0.4} L${x - r * 1.6} ${y} L${x - r * 0.4} ${y - r * 0.4}Z" fill="#fff" stroke="${O}" stroke-width="2"/>`).join('')
  + `<path d="${limb(leftHand)}" fill="none"/>`));
parts.push(part('sunglasses', `<path d="M444 158 L496 158 C496 182 486 192 470 192 C452 192 444 180 444 158Z M504 158 L556 158 C556 180 548 192 530 192 C514 192 504 182 504 158Z" fill="#3a2a4a" stroke="${O}" stroke-width="5" stroke-linejoin="round"/>`
  + line('M496 162 C500 158 500 158 504 162 M444 160 L428 154 M556 160 L572 154', O, 5) + line('M452 166 L462 178 M512 166 L522 178', '#fff', 4) + `<path d="M444 158 L496 158 L494 166 L446 166Z M504 158 L556 158 L554 166 L506 166Z" fill="#e8478f" opacity="0.8"/>`));
parts.push(part('necklace', [...Array(11)].map((_, k) => { const a = Math.PI * (0.08 + 0.84 * k / 10); return `<circle cx="${f(500 + 40 * Math.cos(a))}" cy="${f(282 + 28 * Math.sin(a))}" r="6.5" fill="#fdf8ef" stroke="${O}" stroke-width="2.5"/>`; }).join('')
  + `<path d="M500 312 L512 326 L500 344 L488 326Z" fill="#e8478f" stroke="${O}" stroke-width="3"/>`));

const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1300">
  <!-- The Dress Up doll, one layer per part (rendered one at a time by render.js). Gray and white parts are tinted in the app:
       skin (body), hair (hairBack, hairFront), eye color (eyes) and the outfit color (clothes, beanie, sunHatBand). -->
${parts.join('\n')}
</svg>
`;
fs.writeFileSync(process.argv[2], svg);
console.log(parts.length, 'parts', svg.length, 'bytes');
