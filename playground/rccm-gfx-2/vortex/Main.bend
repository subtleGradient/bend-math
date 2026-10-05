import Base
import ./Controls.bend as Controls
import ./Field.bend as Field
import ./Render.bend as Render
import ./Hud.bend as Hud

def view_shared(+state: Controls.State) -> Controls.State & Image:
  match state:
    case Controls.State{Controls.View{spin_phase, drift_phase, yaw, +admittance, +coupling, paused, orbit, +cutaway}, _, _, _, fps}:
      (state, Render.frame(Field.from_phases(spin_phase, drift_phase, yaw, admittance, coupling, cutaway),
        Hud.Status{admittance, coupling, paused, orbit, cutaway, fps}))

def view(state: Controls.State) -> Controls.State & Image:
  view_shared(state)

def tick(events: List<Event>, state: Controls.State) -> IO(Maybe<Controls.State>):
  do IO<Maybe<Controls.State>>:
    now : Nat <- IO.now()
    return Controls.tick(now, events, state)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("Vortex Study - inspired by Binyamin T. Bair-Mosheh's RCCM asymmetric tensor")
    IO.print("Q/E twist | A/D admittance | C cutaway | Space pause | O orbit")
    IO.print("1 symmetric only | 2 full coupling | 3 reversed | R reset | Esc quit")
    IO.print("Illustrative driven dye field; not a validated CFD solver.")
    # Window.frame maps the image to the next power-of-two square, then crops.
    # Match that square so the entire 512x512 image is visible at 2x scale.
    App.run(~Controls.State, ~App{view, tick}, "RCCM - Vortex Study / Bend 2", 1024, 1024, Controls.initial())
