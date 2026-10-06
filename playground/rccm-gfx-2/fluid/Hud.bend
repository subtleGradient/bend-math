import Base
import ../vortex/Hud.bend as Font
import ./Controls.bend as Controls
import ./Simulation.bend as Sim
import ./Diagnostics.bend as Diag
import ./Grid.bend as Grid
import ../tensor/Matrix4.bend as Matrix
import ../vortex/Math.bend as Math

type Labels is Data:
  Labels{time: String, energy: String, invariant: String, divergence: String,
    pressure: String, selection: String, state: String, mode: String, probe: String}

def glyph(+c: Char) -> U32:
  +g = Font.glyph(c)
  +g = Font.word(Char.is_eq(c, '0'), 488232750, g)
  +g = Font.word(Char.is_eq(c, '4'), 277118249, g)
  +g = Font.word(Char.is_eq(c, '5'), 520633407, g)
  +g = Font.word(Char.is_eq(c, '6'), 488160302, g)
  +g = Font.word(Char.is_eq(c, '7'), 69345823, g)
  +g = Font.word(Char.is_eq(c, '8'), 488159790, g)
  +g = Font.word(Char.is_eq(c, '9'), 210270766, g)
  +g = Font.word(Char.is_eq(c, 'e'), Font.glyph('E'), g)
  +g = Font.word(Char.is_eq(c, '+'), 145536, g)
  +g = Font.word(Char.is_eq(c, '['), 242452711, g)
  Font.word(Char.is_eq(c, ']'), 947126812, g)

def ink(letter: Maybe<&2, Char>, +column: U32, row: U32) -> Bool:
  match letter:
    case None{}:
      False{}
    case Some{c}:
      (column < 5 : U32) &&
        (glyph(c) >> U32.to_nat((row * 5 + column : U32)) .&. 1 > 0 : U32)

def text_inside(inside: Bool, s: String, +dx: U32, dy: U32) -> Bool:
  match inside:
    case False{}:
      False{}
    case True{}:
      ink(String.get(s, U32.to_nat((dx / 6 : U32))), (dx % 6 : U32), dy)

def text(s: String, +x: U32, +y: U32, +ox: U32, +oy: U32) -> Bool:
  text_inside((x >= ox : U32) && (y >= oy : U32) && (y < oy + 6 : U32),
    s, (x - ox : U32), (y - oy : U32))

def mode_name(mode: U32) -> String:
  match mode:
    case 0:
      "E Z / -0.5 TO +0.5"
    case 1:
      "B Z / -0.5 TO +0.5"
    case _:
      "E SQUARED / 0 TO 1"

def state_name(valid: Bool, paused: Bool) -> String:
  match valid paused:
    case False{} _:
      "INVALID / FROZEN"
    case True{} True{}:
      "PAUSED"
    case True{} False{}:
      "RUNNING"

def probe_name(tensor: Maybe<Matrix.Matrix4<F32>>, +slice: U32) -> String:
  match tensor:
    case Some{_}:
      "PROBE " ++ U32.show(slice) ++ " / " ++ U32.show(slice) ++ " / " ++ U32.show(slice)
    case None{}:
      "PROBE INVALID / NO CAPACITY"

# Absolute integrated-norm drift avoids division by a tiny reference norm.
# F32.show is built once per frame, never inside the pixel loop.
def measured(+world: Sim.World, e0: F32, h0: F32, +stats: Diag.Stats,
  paused: Bool, seed: U32, +slice: U32, mode: U32) -> Labels:
  match stats:
    case Diag.Stats{e, h, de, db, peak, _}:
      Labels{"TIME " ++ F32.show(Sim.time(world)),
        "ENERGY DRIFT " ++ F32.show((e - e0 : F32)),
        "INVARIANT DRIFT " ++ F32.show((h - h0 : F32)),
        "MAX DIV " ++ F32.show(Math.max(de, db)),
        "PEAK LOAD " ++ F32.show(peak),
        "SLICE " ++ U32.show(slice) ++ "/15  SEED " ++ U32.show((seed + 1 : U32)),
        state_name(Diag.admissible(stats), paused), mode_name(mode),
        probe_name(Diag.tensor(Grid.centered(Controls.world_grid(world), slice, slice, slice)), slice)}

def labels(scene: Controls.Scene) -> Labels:
  match scene:
    case Controls.Scene{world, Diag.Stats{e0, h0, _, _, _, _},
      stats, paused, seed, slice, mode, _}:
      measured(world, e0, h0, stats, paused, seed, slice, mode)

def color(labels: Labels, +x: U32, +y: U32) -> U32:
  match labels:
    case Labels{time, energy, invariant, divergence, pressure, selection, state, mode, probe}:
      +title = Font.text(~"TRANSVERSE VACUUM", x, y, 24, 12, 2)
      +ink = text(state, x, y, 320, 14) || text(time, x, y, 24, 34) ||
        text(selection, x, y, 264, 34) || text(energy, x, y, 24, 48) ||
        text(invariant, x, y, 264, 48) || text(divergence, x, y, 24, 62) ||
        text(pressure, x, y, 264, 62) || text(mode, x, y, 24, 76) ||
        Font.text(~"XY / Z FIXED", x, y, 24, 91, 1) ||
        Font.text(~"XZ / Y FIXED", x, y, 264, 91, 1) ||
        Font.text(~"YZ / X FIXED", x, y, 24, 289, 1) ||
        Font.text(~"TENSOR / T X Y Z", x, y, 264, 289, 1) ||
        text(probe, x, y, 264, 440) ||
        text("3+1", x, y, 464, 14) ||
        Font.text(~"HIGH", x, y, 454, 91, 1) ||
        Font.text(~"LOW", x, y, 454, 281, 1) ||
        text("MATRIX -2 TO +2 / CLIPPED", x, y, 264, 452) ||
        Font.text(~"NORMALIZED / NOT FEEDBACK", x, y, 264, 464, 1) ||
        Font.text(~"E LOAD ONLY / NOT TOTAL PRESSURE", x, y, 264, 476, 1) ||
        text("SPACE PAUSE  N STEP  R RESET  1/2/3 SEED", x, y, 24, 484) ||
        text("[ ] SLICE  V VIEW  ESC QUIT", x, y, 24, 496)
      +scope = Font.text(~"CAVITY / FORCE CLOSURE NOT IMPLEMENTED", x, y, 264, 76, 1)
      +base = Font.word(ink, 14605522, 0)
      +base = Font.word(scope, 13998706, base)
      Font.word(title, 15657180, base)
