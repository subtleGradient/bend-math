import Base
import ./Controls.bend as C
import ./Simulation.bend as Sim
import ./Diagnostics.bend as Diag
import ./Grid.bend as Grid
import ./Render.bend as R
import ./Hud.bend as Hud
import ../tensor/Matrix4.bend as Matrix

def expect(ok: Bool, +label: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("PASS " ++ label)
    case False{}:
      IO.die(Unit, 1, "FAIL " ++ label)

def scene(state: Maybe<C.State>) -> C.Scene:
  match state:
    case Some{C.State{scene, _, _}}:
      scene
    case None{}:
      C.seeded(0, False{}, 0, 0)

def steps(scene: C.Scene) -> U32:
  match scene:
    case C.Scene{Sim.World{_, steps}, _, _, _, _, _, _, _}:
      steps

def selection(scene: C.Scene, +paused: Bool, seed: U32, slice: U32, mode: U32) -> Bool:
  match scene:
    case C.Scene{_, _, _, p, s, i, m, _}:
      Bool.not(Bool.xor(p, paused)) && U32.is_eq(s, seed) &&
        U32.is_eq(i, slice) && U32.is_eq(m, mode)

def closed(state: Maybe<C.State>) -> Bool:
  match state:
    case None{}:
      True{}
    case Some{_}:
      False{}

def from_scene(scene: C.Scene) -> C.State:
  C.State{scene, 1000n, []}

def input(events: List<Event>, current: C.Scene) -> C.Scene:
  scene(C.tick(1100n, events, from_scene(current)))

def invalid(scene: C.Scene) -> C.Scene:
  match scene:
    case C.Scene{world, baseline, Diag.Stats{e, h, de, db, _, _}, paused, seed, slice, mode, budget}:
      C.Scene{world, baseline, Diag.Stats{e, h, de, db, 1.1, True{}},
        paused, seed, slice, mode, budget}

def main() -> IO(Unit):
  +start : C.Scene = C.seeded(0, False{}, 8, 0)
  +paused : C.Scene = input([Key{32, True{}}, Key{32, True{}}], start)
  +once : C.Scene = input([Key{78, True{}}, Key{110, True{}}], paused)
  +twice : C.Scene = input([Key{110, True{}}, Key{110, False{}}, Key{78, True{}}], once)
  +reset : C.Scene = input([Key{82, True{}}, Key{114, True{}}], C.spend(2n, start))
  +uniform : C.Scene = input([Key{51, True{}}, Key{51, True{}}], once)
  +display : C.Scene = C.seeded(0, True{}, 8, 0)
  +panels : R.Panels = R.panels(display)
  +labels : Hud.Labels = Hud.labels(display)
  +grid : Grid.Grid = C.world_grid(Sim.initial(0))
  +frame : Image = R.frame(display)
  +held_pause : C.State = C.State{paused, 1100n, [32]}
  +held_step : C.State = C.State{once, 1100n, [110]}
  do IO<Unit>:
    expect(selection(paused, True{}, 0, 8, 0) && U32.is_eq(steps(paused), 0),
      "pause edge and duplicate down")
    expect(U32.is_eq(steps(C.advance(0.1, paused)), 0), "paused elapsed ignored")
    expect(selection(scene(C.tick(1200n, [Key{32, True{}}], held_pause)),
      True{}, 0, 8, 0) &&
      U32.is_eq(steps(scene(C.tick(1200n, [Key{78, True{}}], held_step))), 1),
      "held edges persist across frames")
    expect(selection(scene(C.tick(1200n,
      [Key{32, False{}}, Key{32, True{}}], held_pause)), False{}, 0, 8, 0),
      "Space release resumes")
    expect(U32.is_eq(steps(once), 1), "uppercase single-step and held repeat")
    expect(U32.is_eq(steps(twice), 3), "release permits next step")
    expect(U32.is_eq(steps(input([Key{110, True{}}], start)), 4),
      "N while running does not add a step")
    expect(U32.is_eq(steps(C.advance(10.0, start)), 4), "bounded fixed-step catch-up")
    expect(U32.is_eq(steps(C.advance(0.03, start)),
      steps(C.advance(0.02, C.advance(0.01, start)))), "elapsed remainder partition")
    expect(U32.is_eq(steps(scene(C.tick(10000n, [], C.initial()))), 0),
      "first frame discards epoch time")
    expect(U32.is_eq(steps(reset), 0) && selection(reset, False{}, 0, 8, 0),
      "reset edge and stale elapsed discarded")
    expect(U32.is_eq(steps(uniform), 0) && selection(uniform, True{}, 2, 8, 0),
      "reseed preserves pause and discards elapsed")
    expect(selection(input([Key{49, True{}}], uniform), True{}, 0, 8, 0) &&
      selection(input([Key{50, True{}}], uniform), True{}, 1, 8, 0), "all seeds")
    expect(selection(input([Key{91, True{}}, Key{91, True{}}],
      C.seeded(2, True{}, 0, 0)), True{}, 2, 14, 0), "slice down repeats and wraps")
    expect(selection(input([Key{93, True{}}], C.seeded(2, True{}, 15, 0)),
      True{}, 2, 0, 0), "slice up wraps")
    expect(selection(input([Key{86, True{}}, Key{118, True{}}], paused),
      True{}, 0, 8, 1), "view edge uppercase normalization")
    expect(selection(input([Key{118, True{}}], C.seeded(2, True{}, 8, 2)),
      True{}, 2, 8, 0), "view wraps")
    expect(closed(C.tick(1100n, [Close{}], C.initial())) &&
      closed(C.tick(1100n, [Key{27, True{}}], C.initial())), "close and Escape")
    expect(U32.is_eq(steps(C.advance(0.1, invalid(start))), 0) &&
      U32.is_eq(steps(C.step(invalid(paused))), 0), "invalid freezes run and step")
    expect(U32.is_eq(R.pixel(panels, labels, 36, 125),
      R.field_color(0, Grid.centered(grid, 1, 2, 8))), "XY actual centered sample")
    expect(U32.is_eq(R.pixel(panels, labels, 276, 125),
      R.field_color(0, Grid.centered(grid, 1, 8, 2))), "XZ actual centered sample")
    expect(U32.is_eq(R.pixel(panels, labels, 36, 323),
      R.field_color(0, Grid.centered(grid, 8, 1, 2))), "YZ actual centered sample")
    expect(U32.is_eq(R.pixel(panels, labels, 117, 125), 15657180),
      "selected probe crosshair")
    expect(U32.is_eq(R.pixel(panels, labels, 264, 300), 2503740),
      "tensor cell border")
    expect(U32.is_eq(R.pixel(panels, labels, 265, 301),
      R.lookup(R.matrix(Diag.tensor(Grid.centered(grid, 8, 8, 8))), 0, 0, 4)),
      "tensor actual probe value")
    expect(U32.is_eq(R.lookup(R.matrix(None{}), 0, 0, 4), 13998706),
      "invalid tensor sentinel, no fake matrix")
    expect(Bool.not(U32.is_eq(
      R.lookup(R.row(Matrix.Row4{1.0, 1.2, 0.0, 0.0}), 0, 0, 2),
      R.lookup(R.row(Matrix.Row4{1.0, 1.2, 0.0, 0.0}), 1, 0, 2))),
      "tensor display distinguishes above-unit spatial diagonals")
    expect(U32.is_eq(R.pixel(panels, labels, 460, 102), R.signed(0.5, 0.5)) &&
      U32.is_eq(R.pixel(panels, labels, 460, 277), R.signed((0.0 - 0.5 : F32), 0.5)),
      "fixed signed legend endpoints")
    expect(U32.is_eq(R.field_color(1, Grid.centered(grid, 1, 2, 8)),
      R.pixel(R.panels(C.seeded(0, True{}, 8, 1)),
        Hud.labels(C.seeded(0, True{}, 8, 1)), 36, 125)), "B view samples actual state")
    expect(U32.is_eq(R.field_color(2, Grid.centered(grid, 1, 2, 8)),
      R.pixel(R.panels(C.seeded(0, True{}, 8, 2)),
        Hud.labels(C.seeded(0, True{}, 8, 2)), 36, 125)), "pressure view samples actual state")
    expect(U32.is_eq(R.lookup(frame, 36, 125, 512), R.pixel(panels, labels, 36, 125)) &&
      U32.is_eq(R.lookup(frame, 0, 0, 512), 527635), "full native image tile layout")
    expect(U32.is_eq(R.lookup(frame, 24, 12, 512), 15657180),
      "scope title rendered")
    IO.print("UI regressions complete / no manual keyboard-test claim.")
