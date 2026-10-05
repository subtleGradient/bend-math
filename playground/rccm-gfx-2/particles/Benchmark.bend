import Base
import ./Simulation.bend as Simulation
import ./Render.bend as Render
import ./Hud.bend as Hud

# Consumes every pixel. Timings include simulation, binning, rendering,
# CPU checksum and cleanup, not isolated device time or a displayed FPS claim.
def checksum(image: Image) -> U32:
  match image:
    case Pix{color}:
      color
    case Qua{a, b, c, d}:
      (checksum(a) + checksum(b) + checksum(c) + checksum(d) : U32)

def loop(fuel: Nat, world: Simulation.World, +frame: U32, start: Nat, sum: U32) -> IO(Unit):
  match fuel:
    case 0n:
      do IO<Unit>:
        now : Nat <- IO.now()
        IO.print("20 evolved frames including CPU checksum: " ++ Nat.show(Nat.sub(now, start)) ++ " ms")
        IO.print("Checksum: " ++ U32.show(sum))
    case 1n+remaining:
      +next_world = Simulation.evolve(4n, world, Simulation.response(0.82, 1.0))
      next_sum = checksum(Render.frame(next_world, (0.35 + U32.to_f32(frame) * 0.004 : F32), True{},
        Hud.Status{0.82, 1.0, False{}, True{}, True{}, 0, 0}))
      do IO<Unit>:
        barrier : Nat <- IO.now()
        loop(remaining, next_world, (frame + 1 : U32), start, (sum + next_sum : U32))

def main() -> IO(Unit):
  +world = Simulation.evolve(720n, Simulation.initial(0), Simulation.response(0.82, 1.0))
  do IO<Unit>:
    warmup : U32 = checksum(Render.frame(world, 0.35, True{},
      Hud.Status{0.82, 1.0, False{}, True{}, True{}, 0, 0}))
    IO.print("Warm-up checksum: " ++ U32.show(warmup))
    start : Nat <- IO.now()
    loop(20n, world, 0, start, 0)
