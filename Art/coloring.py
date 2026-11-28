"""Line-art coloring pages and the characters drawn on them.

Run from the repo root: python3 Art/coloring.py
Writes AverysPlayground/Activities/ColoringArt.swift (the pages, as SVG path data the app reads), a preview of each
page in Art/coloring/, and a colored picture of each character in Art/pictures/ (render those with Art/render.js).

A page is 400 x 300. Each part is a closed shape the child can fill; later parts sit on top of earlier ones.
Detail lines (eyes, smiles, swirls) are drawn over everything and can't be filled.
"""
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
O = '#4A2C2A'
K = 0.5523  # how far a cubic's handles reach to draw a quarter circle


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def ell(cx, cy, rx, ry=None, rot=0):
    """An ellipse as four cubics, turned by `rot` degrees."""
    ry = rx if ry is None else ry
    a = math.radians(rot)
    def p(x, y):
        return f(cx + x * math.cos(a) - y * math.sin(a)) + ' ' + f(cy + x * math.sin(a) + y * math.cos(a))
    return (f'M{p(rx, 0)} C{p(rx, ry * K)} {p(rx * K, ry)} {p(0, ry)} C{p(-rx * K, ry)} {p(-rx, ry * K)} {p(-rx, 0)} '
            f'C{p(-rx, -ry * K)} {p(-rx * K, -ry)} {p(0, -ry)} C{p(rx * K, -ry)} {p(rx, -ry * K)} {p(rx, 0)} Z')


def rrect(x, y, w, h, r):
    r = min(r, w / 2, h / 2)
    return (f'M{f(x + r)} {f(y)} L{f(x + w - r)} {f(y)} Q{f(x + w)} {f(y)} {f(x + w)} {f(y + r)} L{f(x + w)} {f(y + h - r)} '
            f'Q{f(x + w)} {f(y + h)} {f(x + w - r)} {f(y + h)} L{f(x + r)} {f(y + h)} Q{f(x)} {f(y + h)} {f(x)} {f(y + h - r)} '
            f'L{f(x)} {f(y + r)} Q{f(x)} {f(y)} {f(x + r)} {f(y)} Z')


def poly(*pts):
    return 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in pts) + ' Z'


def star(cx, cy, r, inner=0.45, points=5):
    pts = []
    for i in range(points * 2):
        a = math.pi * i / points - math.pi / 2
        rr = r if i % 2 == 0 else r * inner
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return poly(*pts)


def cloud(cx, cy, s):
    """A puffy cloud: one outline over its bumps."""
    return (f'M{f(cx - 2 * s)} {f(cy + s * .6)} C{f(cx - 2.8 * s)} {f(cy + s * .6)} {f(cx - 2.8 * s)} {f(cy - s * .4)} {f(cx - 1.9 * s)} {f(cy - s * .4)} '
            f'C{f(cx - 1.8 * s)} {f(cy - 1.4 * s)} {f(cx - .5 * s)} {f(cy - 1.6 * s)} {f(cx - .2 * s)} {f(cy - .9 * s)} '
            f'C{f(cx + .3 * s)} {f(cy - 1.8 * s)} {f(cx + 1.9 * s)} {f(cy - 1.4 * s)} {f(cx + 1.8 * s)} {f(cy - .3 * s)} '
            f'C{f(cx + 2.8 * s)} {f(cy - .3 * s)} {f(cx + 2.8 * s)} {f(cy + s * .6)} {f(cx + 2 * s)} {f(cy + s * .6)} Z')


SKY = rrect(0, 0, 400, 300, 0)


class Page:
    def __init__(self, key, name):
        self.key, self.name, self.parts, self.details, self.background = key, name, [], [], 0

    def part(self, d, fill='#FFFFFF', shade=None):
        """A fillable part, with the color (and darker tone) used for the character's colored picture."""
        self.parts.append((d, fill, shade))
        return self

    def detail(self, d, width=3):
        self.details.append((d, width))
        return self


PAGES = []
CHARACTERS = {}  # picture name -> (page, crop box x, y, w, h) for the colored picture


def page(key, name):
    p = Page(key, name)
    PAGES.append(p)
    return p


def band(cx, cy, r1, r2):
    """A rainbow stripe: half a ring from r1 out to r2."""
    def half(r, reverse=False):
        pts = [(cx - r, cy), (cx - r, cy - r * K), (cx - r * K, cy - r), (cx, cy - r), (cx + r * K, cy - r), (cx + r, cy - r * K), (cx + r, cy)]
        if reverse: pts = pts[::-1]
        return pts
    o, i = half(r2), half(r1, True)
    s = f'M{f(o[0][0])} {f(o[0][1])} C' + ' '.join(f'{f(x)} {f(y)}' for x, y in o[1:4]) + ' C' + ' '.join(f'{f(x)} {f(y)}' for x, y in o[4:7])
    s += f' L{f(i[0][0])} {f(i[0][1])} C' + ' '.join(f'{f(x)} {f(y)}' for x, y in i[1:4]) + ' C' + ' '.join(f'{f(x)} {f(y)}' for x, y in i[4:7]) + ' Z'
    return s


def hill(y_left, y_peak, x_peak, y_right):
    return f'M0 {y_left} C{x_peak * .5} {y_peak} {x_peak + (400 - x_peak) * .5} {y_peak} 400 {y_right} L400 300 L0 300 Z'


# Sprinkle the unicorn: Coco's sparkly friend
u = page('unicorn', 'Sprinkle')
u.part(SKY, '#BFE3FF')
for r, color in zip(range(150, 90, -15), ['#F28B9A', '#F9C66B', '#9AD58A', '#8CC8EE']):
    u.part(band(200, 236, r - 15, r), color)
u.part(cloud(58, 70, 18), '#FFFFFF').part(cloud(352, 56, 15), '#FFFFFF')
u.part(star(130, 40, 11), '#F6C945').part(star(372, 128, 9), '#F6C945').part(star(32, 150, 8), '#F6C945')
u.part(hill(250, 226, 200, 254), '#9AD58A', '#7CC26C')
# Tail, then the legs behind the body, then the body, neck, mane, head and the bits on top
u.part('M140 196 C106 186 88 204 94 224 C100 244 84 260 66 266 C98 274 130 256 130 230 C136 248 126 268 108 276 '
       'C146 280 164 246 154 214 Z', '#B57BE0', '#9A5FCB')
for x, y, h in [(146, 222, 58), (172, 228, 52), (214, 228, 52), (240, 222, 58)]:
    u.part(rrect(x, y, 24, h, 12), '#FFFFFF', '#F3E6F6')
    u.part(rrect(x, y + h - 14, 24, 14, 6), '#F7A8C4', '#E58AAD')
u.part(ell(194, 206, 64, 42), '#FFFFFF', '#F3E6F6')
u.part('M220 196 C226 166 238 142 254 128 L296 150 C284 170 270 196 252 210 Z', '#FFFFFF', '#F3E6F6')
u.part('M264 58 C222 46 192 78 204 112 C184 124 182 154 198 166 C184 182 192 208 216 210 C220 198 228 192 238 190 '
       'C232 174 236 160 246 150 C236 134 238 112 252 98 Z', '#C68AF0', '#A86DD8')
u.part(ell(284, 108, 50, 48), '#FFFFFF', '#F3E6F6')
u.part(ell(322, 128, 34, 27), '#FFF3F7', '#F7DCE6')
u.part('M296 72 C298 50 306 38 316 32 C322 48 320 64 312 76 Z', '#FFFFFF', '#F3E6F6')
u.part('M300 70 C304 58 310 48 316 40 C316 54 314 64 308 72 Z', '#F7A8C4')
u.part('M258 66 C274 48 304 50 314 68 C298 64 284 72 278 88 C274 78 266 70 258 66 Z', '#C68AF0', '#A86DD8')
u.part('M276 62 L292 14 L304 64 Q290 70 276 62 Z', '#F6C945', '#E0A92E')
u.part(ell(298, 110, 11, 14), '#FFFFFF')
u.part(ell(300, 112, 7, 9), '#2B2A33')
u.part(ell(304, 108, 2.6), '#FFFFFF')
u.part(ell(330, 146, 9, 6), '#F7A8C4')
u.detail('M281 50 L297 44 M279 38 L295 32 M284 26 L294 22', 2.5)  # the horn's twist
u.detail('M290 96 L286 89 M296 95 L294 87 M302 95 L304 87', 2.5)  # eyelashes
u.detail('M336 120 C338 118 342 118 344 120', 3)  # nostril
u.detail('M310 144 Q318 152 330 148', 3)  # smile
u.detail('M228 84 C214 96 214 112 222 120 M212 134 C202 144 204 156 212 162 M214 178 C206 188 210 198 218 202', 2.5)  # curls in the mane
u.background = 11  # sky, rainbow, clouds, stars and hill: left out of her picture
CHARACTERS['sprinkle'] = (u, (60, 0, 300, 300))


# Bolt the robot: Coco's clever friend who loves to build and code
b = page('robot', 'Bolt')
b.part(SKY, '#BFE3FF')
b.part(cloud(60, 64, 17), '#FFFFFF').part(cloud(340, 70, 15), '#FFFFFF')
b.part(star(330, 150, 10), '#F6C945').part(star(50, 160, 8), '#F6C945').part(star(120, 36, 9), '#F6C945')
b.part(hill(262, 238, 200, 262), '#9AD58A', '#7CC26C')
b.part(rrect(196, 30, 8, 26, 4), '#B9B4C7')
b.part(ell(200, 30, 11), '#E9646E', '#C94A57')
b.part(ell(134, 98, 13), '#F39A5B', '#D97A3A').part(ell(266, 98, 13), '#F39A5B', '#D97A3A')
b.part(rrect(138, 52, 124, 92, 30), '#6EC6CA', '#4FA9AE')
b.part(rrect(156, 68, 88, 60, 20), '#BFE9F2', '#A6DCE8')
b.part(ell(182, 95, 13), '#FFFFFF').part(ell(218, 95, 13), '#FFFFFF')
b.part(ell(184, 97, 6), '#2B2A33').part(ell(220, 97, 6), '#2B2A33')
b.part(ell(170, 114, 7, 4.5), '#F7A8C4').part(ell(230, 114, 7, 4.5), '#F7A8C4')
b.part(rrect(184, 142, 32, 14, 4), '#B9B4C7')
# Arms behind the body: one waving hello, one down
b.part(ell(112, 172, 15, 36, rot=-30), '#6EC6CA', '#4FA9AE').part(ell(92, 136, 17), '#F39A5B', '#D97A3A')
b.part(ell(286, 200, 15, 36, rot=20), '#6EC6CA', '#4FA9AE').part(ell(296, 238, 17), '#F39A5B', '#D97A3A')
b.part(rrect(156, 240, 30, 40, 10), '#B9B4C7', '#9A95AD').part(rrect(214, 240, 30, 40, 10), '#B9B4C7', '#9A95AD')
b.part(rrect(144, 270, 52, 20, 10), '#F39A5B', '#D97A3A').part(rrect(204, 270, 52, 20, 10), '#F39A5B', '#D97A3A')
b.part(rrect(130, 152, 140, 98, 28), '#6EC6CA', '#4FA9AE')
b.part(rrect(156, 168, 88, 60, 16), '#E6F7F8', '#CDEBEE')
b.part(poly((208, 172), (186, 202), (200, 202), (190, 224), (216, 192), (202, 192), (214, 172)), '#F6C945', '#E0A92E')
b.detail('M188 112 Q200 122 212 112', 3)  # smile on his screen
b.detail('M186 92 L188 90 M222 92 L224 90', 2)  # a glint in each eye
b.detail('M150 236 h14 M236 236 h14', 3)  # bolts at his hips
b.background = 7
CHARACTERS['bolt'] = (b, (60, 14, 280, 280))


def scallop(cx, cy, r, bumps, depth, start=0, end=360):
    """A bumpy outline round a circle (curly hair, a cloud of leaves): one bump per step, closed."""
    pts, step = [], (end - start) / bumps
    for i in range(bumps + 1):
        a = math.radians(start + i * step)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    s = f'M{f(pts[0][0])} {f(pts[0][1])}'
    for i in range(bumps):
        a = math.radians(start + (i + 0.5) * step)
        c = (cx + (r + depth) * math.cos(a), cy + (r + depth) * math.sin(a))
        s += f' Q{f(c[0])} {f(c[1])} {f(pts[i + 1][0])} {f(pts[i + 1][1])}'
    return s + ' Z'


# Princess Marisol from the Dominican Republic, in her gown and crown with a Bayahibe rose
m = page('princess', 'Princess Marisol')
m.part(SKY, '#BFE3FF')
m.part(cloud(64, 60, 16), '#FFFFFF').part(cloud(338, 54, 14), '#FFFFFF')
for x, y in [(70, 150), (330, 150), (300, 40)]:
    m.part(f'M{x} {y + 10} C{x - 18} {y - 2} {x - 10} {y - 16} {x} {y - 6} C{x + 10} {y - 16} {x + 18} {y - 2} {x} {y + 10} Z', '#F7A8C4', '#E58AAD')
m.part(hill(268, 250, 200, 268), '#9AD58A', '#7CC26C')
m.part(scallop(200, 112, 54, 14, 12), '#76492F', '#5C3722')
m.part('M172 170 C150 210 128 250 112 290 L288 290 C272 250 250 210 228 170 Z', '#E9559A', '#C94180')
m.part('M140 252 Q170 268 200 254 Q230 268 260 252 L272 276 Q236 292 200 278 Q164 292 128 276 Z', '#F7A8C4', '#E58AAD')
m.part(ell(160, 176, 14, 26, rot=20), '#C68A5E').part(ell(240, 176, 14, 26, rot=-20), '#C68A5E')
m.part(ell(150, 200, 9), '#C68A5E').part(ell(250, 200, 9), '#C68A5E')
m.part(rrect(176, 146, 48, 50, 14), '#E9559A', '#C94180')
m.part(ell(170, 154, 13, 11), '#F7A8C4').part(ell(230, 154, 13, 11), '#F7A8C4')
m.part(rrect(190, 132, 20, 18, 6), '#C68A5E')
m.part(ell(200, 108, 38, 40), '#C68A5E', '#AD7148')
m.part(scallop(200, 84, 30, 6, 9, start=190, end=350) , '#76492F', '#5C3722')
m.part(poly((172, 64), (166, 34), (184, 50), (200, 26), (216, 50), (234, 34), (228, 64)), '#F6C945', '#E0A92E')
m.part(ell(200, 50, 7), '#E8559A')
m.part(ell(186, 110, 5, 6), '#2B2A33').part(ell(214, 110, 5, 6), '#2B2A33')
m.part(ell(178, 124, 7, 4.5), '#F49AC1').part(ell(222, 124, 7, 4.5), '#F49AC1')
m.detail('M190 128 Q200 136 210 128', 3)  # smile
m.detail('M176 104 L172 100 M224 104 L228 100', 2.5)  # lashes
m.detail('M200 200 L200 250 M180 210 L172 246 M220 210 L228 246', 2)  # folds in her gown

# A mermaid on a rock in the sea, with a fish and bubbles
mm = page('mermaid', 'mermaid')
mm.part(SKY, '#BFE3FF')
mm.part(ell(340, 50, 26), '#F6C945', '#E0A92E')
mm.part(cloud(80, 52, 16), '#FFFFFF')
mm.part('M0 170 Q50 158 100 170 T200 170 T300 170 T400 170 L400 300 L0 300 Z', '#7CC0EE', '#4E98D6')
mm.part('M110 300 C112 250 150 226 200 226 C250 226 288 250 290 300 Z', '#B9B4C7', '#9A95AD')
mm.part('M156 220 C150 256 200 262 240 250 C266 242 282 224 292 206 C304 190 320 186 334 196 C322 198 310 206 304 218 C322 214 338 222 344 238 C326 232 308 234 296 244 C272 266 214 276 176 260 C162 252 156 238 156 220 Z', '#5DB35A', '#3F9142')
mm.part(scallop(172, 132, 44, 12, 10, start=100, end=440), '#E9646E', '#C94A57')
mm.part(rrect(156, 160, 40, 72, 18), '#F6CFA8', '#E8B184')
mm.part(ell(166, 176, 10, 8), '#F7A8C4').part(ell(186, 176, 10, 8), '#F7A8C4')
mm.part(ell(140, 196, 9, 26, rot=-30), '#F6CFA8').part(ell(212, 200, 9, 26, rot=40), '#F6CFA8')
mm.part(ell(176, 122, 30, 32), '#F6CFA8', '#E8B184')
mm.part(scallop(176, 104, 26, 6, 8, start=190, end=350), '#E9646E', '#C94A57')
mm.part(ell(166, 124, 4, 5), '#2B2A33').part(ell(188, 124, 4, 5), '#2B2A33')
mm.part(ell(60, 240, 26, 16), '#F39A5B', '#D97A3A').part(poly((84, 240), (104, 226), (104, 254)), '#F39A5B')
mm.part(ell(52, 236, 3.5), '#2B2A33')
for x, y, r in [(80, 200, 6), (92, 186, 4), (350, 250, 7), (360, 230, 4)]:
    mm.part(ell(x, y, r), '#FFFFFF')
mm.detail('M168 136 Q177 142 186 136', 3)
mm.detail('M180 248 Q210 256 240 244 M196 236 Q220 242 246 232', 2)

# A big butterfly over the flowers
bf = page('butterfly', 'butterfly')
bf.part(SKY, '#BFE3FF')
bf.part(ell(60, 50, 24), '#F6C945', '#E0A92E').part(cloud(330, 50, 16), '#FFFFFF')
bf.part(hill(250, 236, 200, 250), '#9AD58A', '#7CC26C')
bf.part('M196 120 C160 50 80 40 70 90 C62 130 110 150 194 140 Z', '#B57BE0', '#9A5FCB')
bf.part('M204 120 C240 50 320 40 330 90 C338 130 290 150 206 140 Z', '#B57BE0', '#9A5FCB')
bf.part('M194 146 C130 150 96 180 110 214 C124 244 170 224 196 160 Z', '#F7A8C4', '#E58AAD')
bf.part('M206 146 C270 150 304 180 290 214 C276 244 230 224 204 160 Z', '#F7A8C4', '#E58AAD')
for x, y, r in [(108, 90, 14), (150, 82, 10), (292, 90, 14), (250, 82, 10), (136, 196, 11), (264, 196, 11)]:
    bf.part(ell(x, y, r), '#F6C945')
bf.part(ell(200, 150, 10, 50), '#76492F', '#5C3722')
bf.part(ell(200, 94, 14), '#76492F', '#5C3722')
bf.part(ell(196, 92, 2.5), '#FFFFFF').part(ell(206, 92, 2.5), '#FFFFFF')
for x in (60, 330):
    bf.part(scallop(x, 262, 14, 6, 8), '#F28B9A').part(ell(x, 262, 7), '#F6C945')
bf.detail('M192 82 C184 60 176 50 166 46 M208 82 C216 60 224 50 234 46', 3)
bf.detail('M194 100 Q200 105 206 100', 2.5)
bf.detail('M60 276 L60 300 M330 276 L330 300', 3)

# A baby T-Rex saying hello
t = page('trex', 'T-Rex')
t.part(SKY, '#BFE3FF')
t.part(ell(56, 50, 24), '#F6C945', '#E0A92E').part(cloud(320, 46, 16), '#FFFFFF')
for x in (40, 350):
    t.part(rrect(x - 6, 150, 12, 120, 6), '#A0673D').part(scallop(x, 140, 26, 8, 10), '#5DB35A', '#3F9142')
t.part(hill(262, 246, 200, 262), '#C9B07A', '#B39760')
t.part('M150 200 C110 204 76 192 54 168 C66 214 110 236 158 232 Z', '#7CC878', '#5DA85A')
t.part(rrect(150, 214, 34, 64, 16), '#7CC878', '#5DA85A').part(rrect(214, 214, 34, 64, 16), '#7CC878', '#5DA85A')
t.part(ell(198, 196, 60, 52), '#7CC878', '#5DA85A')
t.part(ell(212, 208, 32, 32), '#C6EBB0')
t.part('M196 96 C196 60 226 46 262 46 C312 46 340 70 340 108 C340 140 318 160 284 160 L236 160 C210 160 196 142 196 120 Z', '#7CC878', '#5DA85A')
for x in (214, 238, 262):
    t.part(poly((x, 52), (x + 10, 30), (x + 20, 50)), '#F39A5B', '#D97A3A')
t.part(ell(266, 96, 12, 14), '#FFFFFF').part(ell(268, 98, 6, 7), '#2B2A33')
t.part(ell(300, 128, 10, 6), '#F49AC1')
t.part(ell(252, 192, 12, 22, rot=-30), '#7CC878', '#5DA85A')
t.detail('M252 136 Q286 152 324 132', 3.5)
t.detail('M318 92 L322 94', 3)
t.detail('M164 270 h8 M226 270 h8', 3)

# A rainbow castle with flags
c = page('castle', 'castle')
c.part(SKY, '#BFE3FF')
for r, color in zip(range(190, 130, -15), ['#F28B9A', '#F9C66B', '#9AD58A', '#8CC8EE']):
    c.part(band(200, 250, r - 15, r), color)
c.part(cloud(60, 56, 16), '#FFFFFF').part(cloud(344, 46, 14), '#FFFFFF')
c.part(hill(270, 254, 200, 270), '#9AD58A', '#7CC26C')
c.part(rrect(110, 150, 180, 120, 4), '#F7D7E6', '#EBBBD2')
for x in (110, 140, 170, 200, 230, 260):
    c.part(rrect(x, 136, 22, 18, 3), '#F7D7E6', '#EBBBD2')
for x, w, top in [(78, 52, 110), (270, 52, 110)]:
    c.part(rrect(x, top, w, 160, 4), '#F7D7E6', '#EBBBD2')
    c.part(poly((x - 8, top), (x + w / 2, top - 62), (x + w + 8, top)), '#B57BE0', '#9A5FCB')
    c.part(poly((x + w / 2, top - 62), (x + w / 2, top - 92), (x + w / 2 + 24, top - 82), (x + w / 2, top - 72)), '#E9646E')
    c.part(rrect(x + w / 2 - 9, top + 30, 18, 26, 9), '#8CC8EE')
c.part(rrect(166, 110, 68, 60, 4), '#F7D7E6', '#EBBBD2')
c.part(poly((158, 110), (200, 52), (242, 110)), '#5BA8E0', '#3E8BC8')
c.part(poly((200, 52), (200, 22), (224, 32), (200, 42)), '#F6C945')
c.part(ell(200, 136, 14, 16), '#8CC8EE')
c.part('M176 270 L176 222 C176 196 224 196 224 222 L224 270 Z', '#A0673D', '#7E4E2C')
c.part(ell(150, 196, 11, 15), '#8CC8EE').part(ell(250, 196, 11, 15), '#8CC8EE')
c.detail('M200 204 L200 270', 3)
c.detail('M193 244 L195 244 M205 244 L207 244', 3)

# A tall ice cream cone with a cherry
ic = page('icecream', 'ice cream')
ic.part(SKY, '#FFE9F2')
for x, y in [(60, 60), (340, 80), (70, 220), (330, 230)]:
    ic.part(star(x, y, 12), '#F6C945')
ic.part(poly((160, 170), (240, 170), (200, 292)), '#E8B36E', '#C9934E')
ic.part(scallop(200, 168, 46, 10, 10, start=180, end=360), '#F7A8C4', '#E58AAD')
ic.part('M150 172 Q160 196 172 172 Q184 196 196 172 Q208 200 220 172 Q232 196 250 172 L250 160 L150 160 Z', '#F7A8C4', '#E58AAD')
ic.part(scallop(200, 124, 42, 10, 10, start=170, end=370), '#F2E6CF', '#E2CFA8')
ic.part(scallop(200, 84, 36, 10, 9, start=170, end=370), '#9B6A4C', '#7E5236')
ic.part(ell(200, 44, 12), '#E9646E', '#C94A57')
ic.detail('M200 32 C204 20 214 14 222 12', 3)
ic.detail('M172 182 L222 236 M228 182 L180 236 M190 200 L210 200', 2.5)
ic.detail('M176 116 l6 -4 M214 108 l6 4 M196 132 l2 6 M226 124 l-5 4 M184 74 l5 -3 M212 70 l3 5 M196 92 l-5 2', 3)


# A kitty playing with a ball of yarn
k = page('kitty', 'kitty')
k.part(SKY, '#FFF1D6')
k.part(rrect(30, 40, 110, 90, 8), '#BFE3FF').part(rrect(260, 40, 110, 90, 8), '#BFE3FF')
k.part(rrect(0, 230, 400, 70, 0), '#E8B36E', '#C9934E')
k.part(ell(200, 262, 150, 22), '#F28B9A', '#D96A7C')
k.part('M150 220 C120 226 96 208 92 186 C110 200 130 204 150 196 Z', '#F39A5B', '#D97A3A')
k.part(ell(170, 200, 46, 48), '#F39A5B', '#D97A3A')
k.part(ell(176, 214, 24, 28), '#FFF3E0')
k.part(rrect(146, 234, 22, 28, 11), '#F39A5B').part(rrect(184, 234, 22, 28, 11), '#F39A5B')
k.part(poly((140, 112), (138, 72), (166, 98)), '#F39A5B').part(poly((206, 98), (234, 72), (232, 112)), '#F39A5B')
k.part(poly((146, 106), (145, 84), (160, 98)), '#F7A8C4').part(poly((212, 98), (227, 84), (226, 106)), '#F7A8C4')
k.part(ell(186, 130, 50, 42), '#F39A5B', '#D97A3A')
k.part(ell(168, 128, 9, 11), '#FFFFFF').part(ell(204, 128, 9, 11), '#FFFFFF')
k.part(ell(170, 130, 5, 7), '#5DB35A').part(ell(206, 130, 5, 7), '#5DB35A')
k.part(poly((180, 144), (192, 144), (186, 151)), '#F28B9A')
k.part(ell(160, 152, 7, 4.5), '#F7A8C4').part(ell(212, 152, 7, 4.5), '#F7A8C4')
k.part(ell(300, 240, 34), '#5BA8E0', '#3E8BC8')
k.detail('M186 151 L186 158 M176 162 Q186 168 196 162', 3)
k.detail('M150 146 L124 140 M150 152 L124 154 M222 146 L248 140 M222 152 L248 154', 2.5)
k.detail('M150 92 L156 108 M170 86 L172 102 M194 86 L192 102', 2.5)
k.detail('M276 222 C292 236 316 238 330 226 M270 244 C290 262 318 264 334 250 M286 210 C296 230 296 256 288 272', 2.5)
k.detail('M334 240 C352 252 356 274 340 286', 2.5)
k.detail('M85 40 L85 130 M30 85 L140 85 M315 40 L315 130 M260 85 L370 85', 3)

# An owl on a branch under the moon
ow = page('owl', 'owl')
ow.part(SKY, '#33406A')
ow.part(ell(320, 64, 36), '#F6E7B8', '#E9D49A')
for x, y, r in [(60, 50, 9), (130, 30, 7), (240, 40, 8), (370, 140, 7), (40, 170, 7)]:
    ow.part(star(x, y, r), '#F6C945')
ow.part('M0 232 C80 220 160 226 240 222 C300 220 360 214 400 206 L400 226 C360 234 300 240 240 242 C160 246 80 244 0 252 Z', '#A0673D', '#7E4E2C')
ow.part(scallop(330, 206, 22, 7, 8), '#5DB35A', '#3F9142')
ow.part(ell(200, 156, 70, 82), '#9B6A4C', '#7E5236')
ow.part(ell(200, 178, 46, 52), '#E8C9A0', '#D8B484')
ow.part(poly((138, 96), (146, 58), (172, 84)), '#9B6A4C').part(poly((228, 84), (254, 58), (262, 96)), '#9B6A4C')
ow.part(ell(172, 118, 26), '#FFFFFF').part(ell(228, 118, 26), '#FFFFFF')
ow.part(ell(174, 120, 12), '#F6C945').part(ell(226, 120, 12), '#F6C945')
ow.part(ell(175, 121, 6), '#2B2A33').part(ell(225, 121, 6), '#2B2A33')
ow.part(poly((192, 140), (208, 140), (200, 156)), '#F39A5B')
ow.part(ell(136, 172, 18, 44, rot=12), '#7E5236').part(ell(264, 172, 18, 44, rot=-12), '#7E5236')
ow.part(ell(184, 234, 12, 8), '#F39A5B').part(ell(216, 234, 12, 8), '#F39A5B')
ow.detail('M178 168 q6 6 12 0 M210 168 q6 6 12 0 M186 190 q6 6 12 0 M204 190 q6 6 12 0 M196 212 q6 6 12 0', 2.5)

# A rocket zooming past the planets
rk = page('rocket', 'rocket')
rk.part(SKY, '#2E3A59')
for x, y, r in [(50, 40, 8), (120, 250, 7), (350, 30, 9), (370, 200, 7), (30, 160, 6)]:
    rk.part(star(x, y, r), '#F6C945')
rk.part(ell(330, 240, 40), '#F39A5B', '#D97A3A').part(ell(330, 240, 64, 14, rot=-15), '#F6C945')
rk.part(ell(70, 96, 26), '#8CC8EE', '#5BA8E0')
rk.part('M200 270 C186 250 186 236 192 226 L208 226 C214 236 214 250 200 270 Z', '#F6C945', '#F39A5B')
rk.part('M170 210 L150 246 L176 240 Z', '#E9646E', '#C94A57').part('M230 210 L250 246 L224 240 Z', '#E9646E', '#C94A57')
rk.part('M200 36 C232 64 240 120 236 230 L164 230 C160 120 168 64 200 36 Z', '#F2F2F7', '#D8D8E4')
rk.part('M200 36 C214 48 224 62 230 82 L170 82 C176 62 186 48 200 36 Z', '#E9646E', '#C94A57')
rk.part(ell(200, 134, 22), '#5BA8E0', '#3E8BC8')
rk.part(rrect(184, 196, 32, 34, 6), '#E9646E')
rk.detail('M190 126 C192 120 198 116 204 116', 3)
rk.detail('M110 200 l-30 0 M114 214 l-40 0 M290 196 l30 0', 3)

# A race car with a checkered flag
rc = page('racecar', 'race car')
rc.part(SKY, '#BFE3FF')
rc.part(cloud(80, 56, 16), '#FFFFFF').part(cloud(300, 46, 14), '#FFFFFF')
rc.part(rrect(0, 236, 400, 64, 0), '#8A8AA0', '#70708A')
rc.part(rrect(330, 110, 6, 120, 3), '#B9B4C7')
rc.part(rrect(336, 110, 44, 32, 2), '#FFFFFF')
for i in range(4):
    for j in range(2):
        if (i + j) % 2 == 0:
            rc.part(rrect(336 + i * 11, 110 + j * 16, 11, 16, 0), '#2B2A33')
rc.part('M40 210 C40 186 60 176 90 172 L130 170 L160 130 C166 122 176 118 190 118 L250 118 C264 118 274 124 282 134 L304 168 L330 172 C350 176 360 190 360 210 L360 222 L40 222 Z', '#E9646E', '#C94A57')
rc.part('M172 166 L190 136 L226 136 L226 166 Z', '#BFE9F2').part('M238 166 L238 136 L262 136 C268 136 272 140 276 146 L288 166 Z', '#BFE9F2')
rc.part(ell(200, 196, 18), '#FFFFFF')
rc.part(poly((40, 186), (24, 186), (24, 214), (40, 214)), '#F6C945')
rc.part(ell(112, 224, 30), '#3B3A4A').part(ell(112, 224, 14), '#B9B4C7')
rc.part(ell(292, 224, 30), '#3B3A4A').part(ell(292, 224, 14), '#B9B4C7')
rc.part(ell(348, 194, 8, 6), '#F6C945')
rc.detail('M194 190 L200 186 L200 204 M194 204 L206 204', 3)
rc.detail('M20 150 l40 0 M10 170 l30 0 M24 130 l26 0', 3)

# A fairy with wings and a wand
fy = page('fairy', 'fairy')
fy.part(SKY, '#E8F5E2')
for x, y, r in [(60, 60, 9), (340, 50, 10), (40, 200, 7), (360, 190, 8), (110, 30, 6)]:
    fy.part(star(x, y, r), '#F6C945')
fy.part(hill(270, 252, 200, 270), '#9AD58A', '#7CC26C')
fy.part('M190 150 C140 90 80 96 92 140 C100 170 150 176 190 164 Z', '#BFE9F2', '#A6DCE8')
fy.part('M210 150 C260 90 320 96 308 140 C300 170 250 176 210 164 Z', '#BFE9F2', '#A6DCE8')
fy.part('M190 168 C150 186 120 214 136 234 C150 250 178 220 196 178 Z', '#D8C4F5', '#BFA5EA')
fy.part('M210 168 C250 186 280 214 264 234 C250 250 222 220 204 178 Z', '#D8C4F5', '#BFA5EA')
fy.part(scallop(200, 104, 40, 12, 9), '#F6C945', '#E0A92E')
fy.part('M178 160 C168 196 156 236 148 268 L252 268 C244 236 232 196 222 160 Z', '#9AD58A', '#7CC26C')
fy.part(rrect(182, 140, 36, 34, 12), '#9AD58A', '#7CC26C')
fy.part(ell(170, 160, 9, 22, rot=30), '#F6CFA8').part(ell(232, 150, 9, 24, rot=-50), '#F6CFA8')
fy.part(rrect(256, 96, 6, 50, 3), '#B57BE0').part(star(259, 88, 16), '#F6C945')
fy.part(ell(200, 104, 30, 32), '#F6CFA8', '#E8B184')
fy.part(scallop(200, 84, 24, 6, 7, start=190, end=350), '#F6C945', '#E0A92E')
fy.part(ell(190, 106, 4, 5), '#2B2A33').part(ell(210, 106, 4, 5), '#2B2A33')
fy.part(ell(182, 118, 6, 4), '#F49AC1').part(ell(218, 118, 6, 4), '#F49AC1')
fy.part(ell(200, 270, 18, 6), '#F7A8C4')
fy.detail('M192 120 Q200 127 208 120', 3)
fy.detail('M276 76 l8 -8 M282 92 l12 0 M244 70 l-6 -8', 2.5)


def colored_svg(p, crop=None, with_background=True):
    """The page in color, in the app's style: each part filled, a darker lower tone, a thin outline."""
    x, y, w, h = crop or (0, 0, 400, 300)
    out, n = [], 0
    for i, (d, fill, shade) in enumerate(p.parts):
        if not with_background and i < p.background:
            continue
        n += 1
        out.append(f'<clipPath id="k{n}"><path d="{d}"/></clipPath><path d="{d}" fill="{fill}"/>')
        if shade:
            # The darker tone fills the lower part, under a soft curve
            nums = [float(v) for v in __import__('re').findall(r'-?\d+\.?\d*', d)]
            xs, ys = nums[0::2], nums[1::2]
            bx, by, bw, bh = min(xs), min(ys), max(xs) - min(xs), max(ys) - min(ys)
            out.append(f'<g clip-path="url(#k{n})"><ellipse cx="{f(bx + bw / 2)}" cy="{f(by + bh * 1.45)}" rx="{f(bw * 0.9)}" ry="{f(bh * 0.75)}" fill="{shade}"/></g>')
        out.append(f'<path d="{d}" fill="none" stroke="{O}" stroke-width="3.5" stroke-linejoin="round"/>')
    for d, width in p.details:
        out.append(f'<path d="{d}" fill="none" stroke="{O}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x} {y} {w} {h}">\n' + '\n'.join(out) + '\n</svg>\n'


def line_svg(p):
    """The page as the child first sees it: white parts and outlines."""
    out = [f'<path d="{d}" fill="#FFFFFF" stroke="{O}" stroke-width="3" stroke-linejoin="round"/>' for d, _, _ in p.parts]
    out += [f'<path d="{d}" fill="none" stroke="{O}" stroke-width="{w}" stroke-linecap="round"/>' for d, w in p.details]
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 300">\n' + '\n'.join(out) + '\n</svg>\n'


def swift():
    out = ['// Made by Art/coloring.py from its drawings: change the drawings there and run it again, not this file.',
           '', 'extension ColoringPage {']
    for p in PAGES:
        out.append(f'    static let {p.key} = ColoringPage(name: "{p.name}", svg: [')
        out += [f'        "{d}",' for d, _, _ in p.parts]
        out.append('    ], details: [')
        out += [f'        "{d}",' for d, _ in p.details]
        out.append('    ])')
        out.append('')
    out.append('    /// The line-art pages, in the order they come after the first ones.')
    out.append('    static let drawn = [' + ', '.join(p.key for p in PAGES) + ']')
    out.append('}')
    return '\n'.join(out) + '\n'


if __name__ == '__main__':
    for p in PAGES:
        (ROOT / 'Art' / 'coloring' / f'{p.key}.svg').write_text(line_svg(p))
    for name, (p, crop) in CHARACTERS.items():
        (ROOT / 'Art' / 'pictures' / f'{name}.svg').write_text(colored_svg(p, crop, with_background=False))
    (ROOT / 'AverysPlayground' / 'Activities' / 'ColoringArt.swift').write_text(swift())
