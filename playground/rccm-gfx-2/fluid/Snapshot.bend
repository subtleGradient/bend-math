import Base
import ./Controls.bend as Controls
import ./Render.bend as Render

# The same guarded fixed solver steps and renderer, with no native window.
def main() -> Image:
  Render.frame(Controls.spend(4n, Controls.seeded(0, True{}, 8, 0)))
