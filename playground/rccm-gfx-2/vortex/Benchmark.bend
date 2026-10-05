import Base
import ./Field.bend as Field
import ./Render.bend as Render
import ./Hud.bend as Hud

# Consume every pixel; end-to-end timing includes this CPU checksum and cleanup.
# It is not an isolated GPU kernel timer, and makes no cross-machine FPS promise.
def checksum(image: Image) -> U32:
  match image:
    case Pix{color}:
      color
    case Qua{a, b, c, d}:
      (checksum(a) + checksum(b) + checksum(c) + checksum(d) : U32)

def loop(remaining: Nat, +frame: U32, start: Nat, sum: U32) -> IO(Unit):
  match remaining:
    case 0n:
      do IO<Unit>:
        now : Nat <- IO.now()
        IO.print("20 frames including CPU checksum: " ++ Nat.show(Nat.sub(now, start)) ++ " ms")
        IO.print("Checksum: " ++ U32.show(sum))
    case 1n+rest:
      do IO<Unit>:
        next : U32 = checksum(Render.frame(
          Field.scene((U32.to_f32(frame) * 0.05 : F32), 0.35, 0.82, 1.0, False{}),
          Hud.Status{0.82, 1.0, False{}, True{}, False{}, 0}))
        barrier : Nat <- IO.now()
        loop(rest, (frame + 1 : U32), start, (sum + next : U32))

def main() -> IO(Unit):
  do IO<Unit>:
    warmup : U32 = checksum(Render.frame(Field.scene(0.0, 0.35, 0.82, 1.0, False{}),
      Hud.Status{0.82, 1.0, False{}, True{}, False{}, 0}))
    IO.print("Warm-up checksum: " ++ U32.show(warmup))
    start : Nat <- IO.now()
    loop(20n, 0, start, 0)
