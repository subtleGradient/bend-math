import Base
import ./Controls.bend as Controls
import ./Render.bend as Render

def view_shared(+state: Controls.State) -> Controls.State & Image:
  match state:
    case Controls.State{scene, _, _}:
      (state, Render.frame(scene))

def view(state: Controls.State) -> Controls.State & Image:
  view_shared(state)

def tick(events: List<Event>, state: Controls.State) -> IO(Maybe<Controls.State>):
  do IO<Maybe<Controls.State>>:
    now : Nat <- IO.now()
    return Controls.tick(now, events, state)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("TRANSVERSE VACUUM / 3 space + time / periodic 16 cubed")
    IO.print("RCCM paper-linked tensor diagnostic: Binyamin T. Bair-Mosheh.")
    IO.print("https://github.com/subtleGradient/rccm/blob/9cb777b2f23b387e875c1a03353a700d41afdb0e/RCCM-GfX-2.tex")
    IO.print("CAVITY / FORCE CLOSURE NOT IMPLEMENTED. No charges or full fluid.")
    IO.print("Space pause | N step | 1/2/3 waves/pulse/uniform | R reset")
    IO.print("[/] common slice | V signed E Z / B Z / E squared | Esc quit")
    App.run(~Controls.State, ~App{view, tick}, "RCCM / Transverse Vacuum", 1024, 1024, Controls.initial())
