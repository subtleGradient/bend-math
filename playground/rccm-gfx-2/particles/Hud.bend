import Base
import ../vortex/Hud.bend as Font

type Status is Data:
  Status{admittance: F32, coupling: F32, paused: Bool, orbit: Bool, trails: Bool, seed: U32, fps: U32}

# Image coordinates, not window coordinates: 512 square, displayed at 2x.
# RGB words: background 080D13, track 26343C, teal 65C8BD, copper D59A72,
# title EEE8DC, credit A9B3B7, controls DEDCD2, center tick D8D3C7.
# Reuse Font's capitals and text layout. Only missing digits 4/5/6 are local.
def digit(+bits: U32, +x: U32, +y: U32, +ox: U32, +oy: U32) -> Bool:
  +inside = (x >= ox : U32) && (x < ox + 5 : U32) &&
    (y >= oy : U32) && (y < oy + 6 : U32)
  inside && (bits >> U32.to_nat(((y - oy) * 5 + x - ox : U32)) .&. 1 > 0 : U32)

def paused_label(paused: Bool, +x: U32, +y: U32) -> Bool:
  match paused:
    case True{}:
      Font.text(~"PAUSED", x, y, 390, 20, 1)
    case False{}:
      Font.text(~"RUNNING", x, y, 390, 20, 1)

def orbit_label(orbit: Bool, +x: U32, +y: U32) -> Bool:
  match orbit:
    case True{}:
      Font.text(~"ORBIT ON", x, y, 390, 32, 1)
    case False{}:
      Font.text(~"ORBIT OFF", x, y, 390, 32, 1)

def trails_label(trails: Bool, +x: U32, +y: U32) -> Bool:
  match trails:
    case True{}:
      Font.text(~"TRAILS ON", x, y, 390, 44, 1)
    case False{}:
      Font.text(~"TRAILS OFF", x, y, 390, 44, 1)

def seed_label(+seed: U32, +x: U32, +y: U32) -> Bool:
  +braid = U32.is_eq(seed, 0)
  +collision = U32.is_eq(seed, 1)
  +shell = U32.is_eq(seed, 2)
  (braid && Font.text(~"SEED BRAID", x, y, 24, 94, 1)) ||
    (collision && Font.text(~"SEED COLLISION", x, y, 24, 94, 1)) ||
    (shell && Font.text(~"SEED SHELL", x, y, 24, 94, 1))

# Coupling's sign describes the preset family; intermediate values stay visible
# on the meter. The exact zero state is symmetric, not a tolerance band.
def coupling_label(+coupling: F32, +x: U32, +y: U32) -> Bool:
  +positive = (coupling > 0.0 : F32)
  +reverse = (coupling < 0.0 : F32)
  +symmetric = F32.is_eq(coupling, 0.0)
  (positive && Font.text(~"POSITIVE", x, y, 272, 94, 1)) ||
    (reverse && Font.text(~"REVERSE", x, y, 272, 94, 1)) ||
    (symmetric && Font.text(~"SYMMETRIC", x, y, 272, 94, 1))

# Tracks are 200px wide. Clamp only the display: callers keep their own values.
# Admittance maps .55..1 to left-to-right; coupling maps -2..2 around x372.
# Teal grows left for reverse coupling; copper grows right for positive.
def meters(+admittance: F32, +coupling: F32, +x: U32) -> U32:
  +a = Font.unit(((admittance - 0.55) / 0.45 : F32))
  +c = Font.unit(((coupling + 2.0) / 4.0 : F32))
  +position = U32.to_f32(x)
  +left = (x >= 24 : U32) && (x < 224 : U32)
  +right = (x >= 272 : U32) && (x < 472 : U32)
  +a_fill = left && (position < 24.0 + 200.0 * a : F32)
  +negative = right && (position < 372.0 : F32) &&
    (position >= 272.0 + 200.0 * c : F32)
  +positive = right && (position >= 372.0 : F32) &&
    (position < 272.0 + 200.0 * c : F32)
  +base = Font.word(left || right, 2503740, 527635)
  +base = Font.word(a_fill || negative, 6670525, base)
  +base = Font.word(positive, 13998706, base)
  Font.word(U32.is_eq(x, 372), 14209991, base)

def header(status: Status, +x: U32, +y: U32) -> U32:
  match status:
    case Status{admittance, +coupling, paused, orbit, trails, seed, _}:
      +title = Font.text(~"PARTICLE LOOM", x, y, 24, 20, 2)
      +credit = Font.text(~"BINYAMIN T. BAIR-MOSHEH / BEND 2", x, y, 24, 44, 1)
      +labels = Font.text(~"ADMITTANCE .  /1", x, y, 24, 64, 1) ||
        digit(520633407, x, y, 96, 64) || digit(520633407, x, y, 102, 64) ||
        Font.text(~"COUPLING -2/2", x, y, 272, 64, 1)
      +state = paused_label(paused, x, y) || orbit_label(orbit, x, y) ||
        trails_label(trails, x, y)
      +seed_ink = seed_label(seed, x, y)
      +coupling_ink = coupling_label(coupling, x, y)
      +meter_row = (y >= 78 : U32) && (y < 82 : U32)
      +base = Font.word(meter_row, meters(admittance, coupling, x), 527635)
      +base = Font.word(U32.is_eq(y, 107), 2503740, base)
      +base = Font.word(credit, 11121591, base)
      +base = Font.word(labels || state || seed_ink, 6670525, base)
      +base = Font.word(coupling_ink, 13998706, base)
      +base = Font.word(title, 15657180, base)
      +teal_mark = (x >= 24 : U32) && (x < 46 : U32) && U32.is_eq(y, 10)
      +copper_mark = (x >= 50 : U32) && (x < 72 : U32) && U32.is_eq(y, 10)
      +base = Font.word(teal_mark, 6670525, base)
      Font.word(copper_mark, 13998706, base)

def footer(+x: U32, +y: U32) -> U32:
  +keys = Font.text(~"Q/E COUPLING  A/D ADMITTANCE", x, y, 24, 462, 1) ||
    Font.text(~"SPACE PAUSE  O ORBIT  T TRAILS", x, y, 24, 472, 1) ||
    Font.text(~"1 SYMMETRIC  2 COUPLED  3 REVERSE", x, y, 24, 482, 1) ||
    Font.text(~" / /  SEEDS  B BURST  R RESET", x, y, 24, 492, 1) ||
    digit(277118249, x, y, 24, 492) ||
    digit(520633407, x, y, 36, 492) ||
    digit(488160302, x, y, 48, 492)
  +note = Font.text(~"ILLUSTRATIVE / NOT VALIDATED PHYSICS", x, y, 24, 502, 1)
  +base = Font.word(U32.is_eq(y, 452), 2503740, 527635)
  +base = Font.word(keys, 14605522, base)
  Font.word(note, 13998706, base)

def overlay(top: Bool, bottom: Bool, status: Status, +x: U32, +y: U32) -> U32:
  match top bottom:
    case True{} _:
      header(status, x, y)
    case False{} True{}:
      footer(x, y)
    case False{} False{}:
      0

# Zero is the caller's transparent sentinel, not alpha-packed black.
# FPS is accepted but omitted so the controls and physics caveat stay readable.
def color(status: Status, +x: U32, +y: U32) -> U32:
  overlay((x < 512 : U32) && (y < 108 : U32),
    (x < 512 : U32) && (y >= 452 : U32) && (y < 512 : U32), status, x, y)
