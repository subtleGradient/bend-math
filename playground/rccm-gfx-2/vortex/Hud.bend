import Base

type Status is Data:
  Status{admittance: F32, coupling: F32, paused: Bool, orbit: Bool, cutaway: Bool, fps: U32}

# RGB palette: 080D13 background, 26343C track, 65C8BD teal, D59A72 copper,
# D8D3C7 center tick, A9B3B7 credit, EEE8DC title, DEDCD2 controls.
# Bend spells the packed U32 values below in decimal.
def word(condition: Bool, yes: U32, no: U32) -> U32:
  match condition:
    case True{}:
      yes
    case False{}:
      no

def scalar(condition: Bool, yes: F32, no: F32) -> F32:
  match condition:
    case True{}:
      yes
    case False{}:
      no

def unit(+value: F32) -> F32:
  +low = scalar((value > 0.0 : F32), value, 0.0)
  scalar((low < 1.0 : F32), low, 1.0)

# Handmade 5x6 capitals. Six rows of five bits, low bit is the left pixel.
# One blank column separates letters; absent characters (including space) are blank.
# Typed word chains avoid the U32 literal-match expansion in GPU shaders.
def glyph(+c: Char) -> U32:
  +g = {0 : U32}
  +g = word(Char.is_eq(c, 'A'), 588840494, g)
  +g = word(Char.is_eq(c, 'B'), 521715247, g)
  +g = word(Char.is_eq(c, 'C'), 1007715390, g)
  +g = word(Char.is_eq(c, 'D'), 521717295, g)
  +g = word(Char.is_eq(c, 'E'), 1041284159, g)
  +g = word(Char.is_eq(c, 'F'), 34651199, g)
  +g = word(Char.is_eq(c, 'G'), 1025410110, g)
  +g = word(Char.is_eq(c, 'H'), 588840497, g)
  +g = word(Char.is_eq(c, 'I'), 1044517023, g)
  +g = word(Char.is_eq(c, 'J'), 211034396, g)
  +g = word(Char.is_eq(c, 'K'), 580033841, g)
  +g = word(Char.is_eq(c, 'L'), 1041269793, g)
  +g = word(Char.is_eq(c, 'M'), 588830577, g)
  +g = word(Char.is_eq(c, 'N'), 589092465, g)
  +g = word(Char.is_eq(c, 'O'), 488162862, g)
  +g = word(Char.is_eq(c, 'P'), 35112495, g)
  +g = word(Char.is_eq(c, 'Q'), 1033422382, g)
  +g = word(Char.is_eq(c, 'R'), 580042287, g)
  +g = word(Char.is_eq(c, 'S'), 520632382, g)
  +g = word(Char.is_eq(c, 'T'), 138547359, g)
  +g = word(Char.is_eq(c, 'U'), 488162865, g)
  +g = word(Char.is_eq(c, 'V'), 145278513, g)
  +g = word(Char.is_eq(c, 'W'), 599442993, g)
  +g = word(Char.is_eq(c, 'X'), 581046609, g)
  +g = word(Char.is_eq(c, 'Y'), 138547537, g)
  +g = word(Char.is_eq(c, 'Z'), 1041305887, g)
  +g = word(Char.is_eq(c, '/'), 35787024, g)
  +g = word(Char.is_eq(c, '-'), 31744, g)
  +g = word(Char.is_eq(c, '.'), 134217728, g)
  +g = word(Char.is_eq(c, '1'), 474091716, g)
  +g = word(Char.is_eq(c, '2'), 1042424366, g)
  word(Char.is_eq(c, '3'), 488124943, g)

def ink(letter: Maybe<&2, Char>, column: U32, row: U32) -> Bool:
  match letter:
    case None{}:
      False{}
    case Some{c}:
      (glyph(c) >> U32.to_nat((row * 5 + column : U32)) .&. 1 > 0 : U32)

# Keep string literals behind the bounds test, rather than constructing them
# for every pixel in a bar. Templates specialize only these few fixed labels.
def text_inside(~s: String, inside: Bool, +dx: U32, dy: U32, +scale: U32) -> Bool:
  match inside:
    case False{}:
      False{}
    case True{}:
      +column = (dx / scale % 6 : U32)
      (column < 5 : U32) && ink(
        String.get(s, U32.to_nat((dx / scale / 6 : U32))), column, (dy / scale : U32))

def text(~s: String, +x: U32, +y: U32, +ox: U32, +oy: U32, +scale: U32) -> Bool:
  text_inside(~s, (x >= ox : U32) && (y >= oy : U32) && (y < oy + 6 * scale : U32),
    (x - ox : U32), (y - oy : U32), scale)

def paused_label(paused: Bool, +x: U32, +y: U32) -> Bool:
  match paused:
    case True{}:
      text(~"PAUSED", x, y, 390, 24, 1)
    case False{}:
      text(~"RUNNING", x, y, 390, 24, 1)

def orbit_label(orbit: Bool, +x: U32, +y: U32) -> Bool:
  match orbit:
    case True{}:
      text(~"ORBIT ON", x, y, 390, 38, 1)
    case False{}:
      text(~"ORBIT OFF", x, y, 390, 38, 1)

def cutaway_label(cutaway: Bool, +x: U32, +y: U32) -> Bool:
  match cutaway:
    case True{}:
      text(~"CUT ON", x, y, 390, 50, 1)
    case False{}:
      text(~"CUT OFF", x, y, 390, 50, 1)

# Both tracks are 200 pixels wide. Admittance fills left-to-right; coupling
# grows outwards from the center, making its sign visible without numeric text.
def meters(+admittance: F32, +coupling: F32, +x: U32) -> U32:
  +a = unit(((admittance - 0.55) / 0.45 : F32))
  +c = unit(((coupling + 2.0) / 4.0 : F32))
  +position = U32.to_f32(x)
  +left = (x >= 24 : U32) && (x < 224 : U32)
  +right = (x >= 272 : U32) && (x < 472 : U32)
  +a_fill = left && (position < 24.0 + 200.0 * a : F32)
  +c_fill = right && (
    ((position >= 372.0 : F32) && (position < 272.0 + 200.0 * c : F32)) ||
    ((position < 372.0 : F32) && (position >= 272.0 + 200.0 * c : F32)))
  +base = word(left || right, 2503740, 527635)
  +base = word(a_fill, 6670525, base)
  +base = word(c_fill, 13998706, base)
  word(U32.is_eq(x, 372), 14209991, base)

def header(status: Status, +x: U32, +y: U32) -> U32:
  match status:
    case Status{admittance, coupling, paused, orbit, cutaway, _}:
      +title = text(~"VORTEX STUDY", x, y, 24, 22, 2)
      +credit = text(~"BINYAMIN T. BAIR-MOSHEH / BEND 2", x, y, 24, 48, 1)
      +labels = text(~"ADMITTANCE", x, y, 24, 76, 1) ||
        text(~"COUPLING", x, y, 272, 76, 1)
      +mode = paused_label(paused, x, y) || orbit_label(orbit, x, y) ||
        cutaway_label(cutaway, x, y)
      +meter_row = (y >= 88 : U32) && (y < 92 : U32)
      +base = word(meter_row, meters(admittance, coupling, x), 527635)
      +base = word(credit, 11121591, base)
      +base = word(labels || mode, 6670525, base)
      +base = word(title, 15657180, base)
      word((x >= 24 : U32) && (x < 46 : U32) && U32.is_eq(y, 12), 13998706, base)

def footer(+x: U32, +y: U32) -> U32:
  +keys = text(~"Q/E TWIST  A/D ADMITTANCE  C CUTAWAY", x, y, 24, 454, 1) ||
    text(~"SPACE PAUSE  O ORBIT  1/2/3 PRESETS  R RESET", x, y, 24, 468, 1)
  +note = text(~"RCCM-INSPIRED / NOT VALIDATED CFD", x, y, 24, 492, 1)
  +base = word(U32.is_eq(y, 440), 2503740, 527635)
  +base = word(keys, 14605522, base)
  word(note, 13998706, base)

def overlay(top: Bool, bottom: Bool, status: Status, +x: U32, +y: U32) -> U32:
  match top bottom:
    case True{} _:
      header(status, x, y)
    case False{} True{}:
      footer(x, y)
    case False{} False{}:
      0

# Only the two bars are opaque. The full volume between y112 and y439 is untouched.
# FPS is accepted as part of the shared status API, but omitted to keep the HUD quiet.
def color(status: Status, +x: U32, +y: U32) -> U32:
  overlay((x < 512 : U32) && (y < 112 : U32),
    (x < 512 : U32) && (y >= 440 : U32) && (y < 512 : U32), status, x, y)
