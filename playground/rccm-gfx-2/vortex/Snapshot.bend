import Base
import ./Field.bend as Field
import ./Render.bend as Render
import ./Hud.bend as Hud

# Headless deterministic image, with the same renderer as the interactive app.
def main() -> Image:
  Render.frame(Field.scene(2.0, 0.35, 0.82, 1.0, False{}),
    Hud.Status{0.82, 1.0, False{}, True{}, False{}, 0})
