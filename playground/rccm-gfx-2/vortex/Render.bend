import Base
import ./FloatTensor.bend as Tensor
import ./Field.bend as Field
import ./Math.bend as Math
import ./Hud.bend as Hud

# 512x512 image. Fork to 4x4 tiles, then build each tile without parallel calls:
# 4^7 = 16384 leaves in one GPU dispatch, following bend guide shaders.
def march(
  steps: Nat, +scene: Field.Scene,
  +x: F32, +y: F32, +z: F32, +dx: F32, +dy: F32, +dz: F32,
  +step_size: F32, +transmission: F32, red: F32, green: F32, blue: F32
) -> Tensor.Vector3:
  match steps:
    case 0n:
      Tensor.Vector3{red, green, blue}
    case 1n+remaining:
      +sample = Field.sample(scene, x, y, z)
      +density = Field.density(sample)
      +heat = Field.heat(sample)
      +opacity = Math.min(0.4, (density * step_size * 3.0 : F32))
      +light = (transmission * opacity * (0.65 + 0.55 * density) : F32)
      march(remaining, scene, (x + dx : F32), (y + dy : F32), (z + dz : F32),
        dx, dy, dz, step_size, (transmission * (1.0 - opacity) : F32),
        (red + light * (0.12 + 2.2 * heat) : F32),
        (green + light * (0.8 - 0.25 * heat) : F32),
        (blue + light * (1.9 - 1.8 * heat) : F32))

def finish(color: Tensor.Vector3) -> U32:
  match color:
    case Tensor.Vector3{red, green, blue}:
      Math.pack(Math.tone((red + 0.0015 : F32)),
        Math.tone((green + 0.0025 : F32)), Math.tone((blue + 0.0045 : F32)))

def intersection(
  hit: Bool, scene: Field.Scene, +projection: F32, discriminant: F32,
  +ox: F32, +oy: F32, +oz: F32, +dx: F32, +dy: F32, +dz: F32
) -> U32:
  match hit:
    case False{}:
      Math.pack(0.039, 0.05, 0.067)
    case True{}:
      +half_length = F32.sqrt(discriminant)
      +step_size = (2.0 * half_length / 64.0 : F32)
      +start = (projection - half_length + 0.5 * step_size : F32)
      finish(march(64n, scene,
        (ox + start * dx : F32), (oy + start * dy : F32), (oz + start * dz : F32),
        (dx * step_size : F32), (dy * step_size : F32), (dz * step_size : F32),
        step_size, 1.0, 0.0, 0.0, 0.0))

def volume_pixel(+scene: Field.Scene, x: U32, y: U32) -> U32:
  Field.Scene{_, _, _, _, _, +yaw_cos, +yaw_sin, _} = scene
  +screen_x = ((U32.to_f32(x) + 0.5 - 256.0) / 512.0 : F32)
  +screen_y = ((256.0 - U32.to_f32(y) - 0.5) / 512.0 : F32)
  +ox = (3.8060 * yaw_sin : F32)
  +oy = {1.7776 : F32}
  +oz = (3.8060 * yaw_cos : F32)
  +raw_x = ((0.0 - 0.9062 * yaw_sin) + screen_x * yaw_cos - screen_y * 0.4232 * yaw_sin : F32)
  +raw_y = ((0.0 - 0.4232) + screen_y * 0.9062 : F32)
  +raw_z = ((0.0 - 0.9062 * yaw_cos) - screen_x * yaw_sin - screen_y * 0.4232 * yaw_cos : F32)
  +inverse_length = (1.0 / F32.sqrt((raw_x * raw_x + raw_y * raw_y + raw_z * raw_z : F32)) : F32)
  +dx = (raw_x * inverse_length : F32)
  +dy = (raw_y * inverse_length : F32)
  +dz = (raw_z * inverse_length : F32)
  +projection = (0.0 - ox * dx - oy * dy - oz * dz : F32)
  +discriminant = (projection * projection - ox * ox - oy * oy - oz * oz + 3.24 : F32)
  intersection((discriminant > 0.0 : F32), scene, projection, discriminant, ox, oy, oz, dx, dy, dz)

def composite(transparent: Bool, color: U32, scene: Field.Scene, x: U32, y: U32) -> U32:
  match transparent:
    case True{}:
      volume_pixel(scene, x, y)
    case False{}:
      color

def pixel(scene: Field.Scene, status: Hud.Status, +x: U32, +y: U32) -> U32:
  +overlay = Hud.color(status, x, y)
  composite(U32.is_eq(overlay, 0), overlay, scene, x, y)

def block2(+scene: Field.Scene, +status: Hud.Status, +x: U32, +y: U32) -> Image:
  Qua{Pix{pixel(scene, status, x, y)}, Pix{pixel(scene, status, (x + 1 : U32), y)},
    Pix{pixel(scene, status, x, (y + 1 : U32))}, Pix{pixel(scene, status, (x + 1 : U32), (y + 1 : U32))}}

def block4(+scene: Field.Scene, +status: Hud.Status, +x: U32, +y: U32) -> Image:
  Qua{block2(scene, status, x, y), block2(scene, status, (x + 2 : U32), y),
    block2(scene, status, x, (y + 2 : U32)), block2(scene, status, (x + 2 : U32), (y + 2 : U32))}

def tiles(+depth: Nat, +scene: Field.Scene, +status: Hud.Status, +x: U32, +y: U32, +size: U32) -> Image:
  match depth:
    case 0n:
      block4(scene, status, x, y)
    case 1n+remaining:
      +half = (size / 2 : U32)
      a b c d = tiles(remaining, scene, status, x, y, half)
        tiles(remaining, scene, status, (x + half : U32), y, half)
        tiles(remaining, scene, status, x, (y + half : U32), half)
        tiles(remaining, scene, status, (x + half : U32), (y + half : U32), half)
      Qua{a, b, c, d}

def frame(scene: Field.Scene, status: Hud.Status) -> Image:
  tiles!(7n, scene, status, 0, 0, 512)
