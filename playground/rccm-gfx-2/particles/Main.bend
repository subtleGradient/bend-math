import Base
import ./Controls.bend as Controls
import ./Render.bend as Render
import ./Hud.bend as Hud

def view_shared(+state: Controls.State) -> Controls.State & Image:
  match state:
    case Controls.State{Controls.Scene{world, admittance, coupling, paused, orbit, +trails, seed, yaw, _}, _, _, _, fps, _}:
      (state, Render.frame(world, yaw, trails, Hud.Status{admittance, coupling, paused, orbit, trails, seed, fps}))

def view(state: Controls.State) -> Controls.State & Image:
  view_shared(state)

def tick(events: List<Event>, state: Controls.State) -> IO(Maybe<Controls.State>):
  do IO<Maybe<Controls.State>>:
    now : Nat <- IO.now()
    return Controls.tick(now, events, state)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("Particle Loom - inspired by Binyamin T. Bair-Mosheh's RCCM asymmetric tensor")
    IO.print("256 interacting particles, matrix-derived radial and handed pair responses.")
    IO.print("Q/E coupling | A/D admittance | Space pause | O orbit | T trails")
    IO.print("1 symmetric | 2 coupled | 3 reverse | 4/5/6 seeds | B burst | R reset | Esc quit")
    IO.print("Invented dimensionless dynamics for illustration; not validated physics.")
    App.run(~Controls.State, ~App{view, tick}, "RCCM - Particle Loom / Bend 2", 1024, 1024, Controls.initial())
