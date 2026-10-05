import Base
import ./Simulation.bend as Simulation
import ./Render.bend as Render
import ./Hud.bend as Hud

# Same evolving particles and renderer as the live app, no window.
# 720 fixed steps = 6 toy seconds. Edit seed/coupling here for comparison stills.
def main() -> Image:
  Render.frame(Simulation.evolve(720n, Simulation.initial(0), Simulation.response(0.82, 1.0)),
    0.35, True{}, Hud.Status{0.82, 1.0, False{}, False{}, True{}, 0, 0})
