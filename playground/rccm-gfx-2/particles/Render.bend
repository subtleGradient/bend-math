import Base
import ../vortex/FloatTensor.bend as Tensor
import ../vortex/Math.bend as Math
import ./Simulation.bend as Simulation
import ./Vector.bend as Vector
import ./Hud.bend as Hud

type Camera is Data:
  Camera{cos_yaw: F32, sin_yaw: F32}

type Point is Data:
  Point{x: F32, y: F32, scale: F32}

# Projected emissive line segments, including zero-length particle heads.
# Screen bounds are cached once; no per-pixel walks over the particle tree.
type Stroke is Data:
  Stroke{ax: F32, ay: F32, dx: F32, dy: F32, inverse_length: F32,
    inverse_width: F32, energy: F32, warm: Bool,
    left: F32, top: F32, right: F32, bottom: F32}

type Cells is Data:
  Cell{strokes: List<&2, Stroke>}
  Four{tl: Cells, tr: Cells, bl: Cells, br: Cells}

def project(camera: Camera, position: Tensor.Vector3) -> Point:
  match camera position:
    case Camera{+cos_yaw, +sin_yaw} Tensor.Vector3{+x, +y, +z}:
      +horizontal = (cos_yaw * x - sin_yaw * z : F32)
      +depth = (sin_yaw * x + cos_yaw * z : F32)
      +scale = (5.5 / Math.max(1.0, (5.5 + 0.92 * depth + 0.39 * y : F32)) : F32)
      Point{(256.0 + 115.0 * scale * horizontal : F32),
        (280.0 - 115.0 * scale * (0.92 * y - 0.39 * depth) : F32), scale}

def stroke(start: Point, end: Point, +width: F32, energy: F32, warm: Bool) -> Stroke:
  match start end:
    case Point{+ax, +ay, _} Point{+bx, +by, _}:
      +dx = (bx - ax : F32)
      +dy = (by - ay : F32)
      Stroke{ax, ay, dx, dy, (1.0 / Math.max(0.0001, (dx * dx + dy * dy : F32)) : F32),
        (1.0 / (width * width : F32) : F32), energy, warm,
        (Math.min(ax, bx) - width : F32), (Math.min(ay, by) - width : F32),
        (Math.max(ax, bx) + width : F32), (Math.max(ay, by) + width : F32)}

def traces(history: List<&2, Tensor.Vector3>, +camera: Camera, +warm: Bool,
  +age: F32, +previous: Point, acc: List<&2, Stroke>) -> List<&2, Stroke>:
  match history:
    case []:
      acc
    case position <> rest:
      +next = project(camera, position)
      +fade = Math.max(0.0, (1.0 - age / 14.0 : F32))
      traces(rest, camera, warm, (age + 1.0 : F32), next,
        stroke(previous, next, 2.8, (0.55 * fade * fade : F32), warm) <> acc)

def trail_strokes(enabled: Bool, history: List<&2, Tensor.Vector3>, camera: Camera,
  warm: Bool, point: Point, acc: List<&2, Stroke>) -> List<&2, Stroke>:
  match enabled:
    case False{}:
      acc
    case True{}:
      traces(history, camera, warm, 0.0, point, acc)

def body_strokes(body: Simulation.Body, +camera: Camera, trails: Bool,
  acc: List<&2, Stroke>) -> List<&2, Stroke>:
  match body:
    case Simulation.Body{_, spin, position, velocity, history}:
      +point = project(camera, position)
      +warm = (spin < 0.0 : F32)
      width = (4.1 + 0.4 * F32.sqrt(Vector.length_squared(velocity)) : F32)
      trail_strokes(trails, history, camera, warm, point,
        stroke(point, point, width, 3.0, warm) <> acc)

def strokes(particles: Simulation.Particles, +camera: Camera, +trails: Bool,
  acc: List<&2, Stroke>) -> List<&2, Stroke>:
  match particles:
    case Simulation.One{body}:
      body_strokes(body, camera, trails, acc)
    case Simulation.Two{left, right}:
      strokes(left, camera, trails, strokes(right, camera, trails, acc))

def keep(inside: Bool, candidate: Stroke, acc: List<&2, Stroke>) -> List<&2, Stroke>:
  match inside:
    case True{}:
      candidate <> acc
    case False{}:
      acc

def intersects(candidate: Stroke, +x: F32, +y: F32, +size: F32) -> Bool:
  match candidate:
    case Stroke{_, _, _, _, _, _, _, _, left, top, right, bottom}:
      (right >= x : F32) && (bottom >= y : F32) &&
        (left < x + size : F32) && (top < y + size : F32)

def filter(strokes: List<&2, Stroke>, +x: F32, +y: F32, +size: F32,
  acc: List<&2, Stroke>) -> List<&2, Stroke>:
  match strokes:
    case []:
      acc
    case +candidate <> rest:
      filter(rest, x, y, size, keep(intersects(candidate, x, y, size), candidate, acc))

# Host bins into 32x32 cells. Each later device tile sees only nearby segments.
def cells(+depth: Nat, +strokes: List<&2, Stroke>, +x: F32, +y: F32, +size: F32) -> Cells:
  match depth:
    case 0n:
      Cell{strokes}
    case 1n+remaining:
      +half = (size * 0.5 : F32)
      Four{
        cells(remaining, filter(strokes, x, y, half, []), x, y, half),
        cells(remaining, filter(strokes, (x + half : F32), y, half, []), (x + half : F32), y, half),
        cells(remaining, filter(strokes, x, (y + half : F32), half, []), x, (y + half : F32), half),
        cells(remaining, filter(strokes, (x + half : F32), (y + half : F32), half, []),
          (x + half : F32), (y + half : F32), half)}

def energy(candidate: Stroke, +x: F32, +y: F32) -> F32:
  match candidate:
    case Stroke{+ax, +ay, +dx, +dy, inverse_length, inverse_width, energy, _, _, _, _, _}:
      +t = Math.clamp(((dx * (x - ax) + dy * (y - ay)) * inverse_length : F32), 0.0, 1.0)
      +rx = (x - ax - t * dx : F32)
      +ry = (y - ay - t * dy : F32)
      +kernel = Math.max(0.0, (1.0 - (rx * rx + ry * ry) * inverse_width : F32))
      (energy * kernel * kernel * kernel : F32)

def lit(strokes: List<&2, Stroke>, +x: F32, +y: F32, cool: F32, copper: F32) -> F32 & F32:
  match strokes:
    case []:
      (cool, copper)
    case +candidate <> rest:
      Stroke{_, _, _, _, _, _, _, +warm, _, _, _, _} = candidate
      +amount = energy(candidate, x, y)
      lit(rest, x, y, (cool + Math.pick(warm, 0.0, amount) : F32),
        (copper + Math.pick(warm, amount, 0.0) : F32))

def finish_pixel(+x: U32, +y: U32, values: F32 & F32) -> U32:
  (+cool, +copper) = values
  +grid = Math.pick(U32.is_eq((x % 32 : U32), 0) && U32.is_eq((y % 32 : U32), 24), 0.004, 0.0)
  Math.pack(Math.tone((0.0015 + grid + 0.16 * cool + 1.8 * copper : F32)),
    Math.tone((0.0025 + grid + 1.25 * cool + 0.65 * copper : F32)),
    Math.tone((0.0045 + grid + 1.75 * cool + 0.16 * copper : F32)))

def particle_pixel(strokes: List<&2, Stroke>, +x: U32, +y: U32) -> U32:
  finish_pixel(x, y, lit(strokes, (U32.to_f32(x) + 0.5 : F32), (U32.to_f32(y) + 0.5 : F32), 0.0, 0.0))

def composite(transparent: Bool, overlay: U32, strokes: List<&2, Stroke>, x: U32, y: U32) -> U32:
  match transparent:
    case True{}:
      particle_pixel(strokes, x, y)
    case False{}:
      overlay

def pixel(strokes: List<&2, Stroke>, status: Hud.Status, +x: U32, +y: U32) -> U32:
  +overlay = Hud.color(status, x, y)
  composite(U32.is_eq(overlay, 0), overlay, strokes, x, y)

def block2(+strokes: List<&2, Stroke>, +status: Hud.Status, +x: U32, +y: U32) -> Image:
  Qua{Pix{pixel(strokes, status, x, y)}, Pix{pixel(strokes, status, (x + 1 : U32), y)},
    Pix{pixel(strokes, status, x, (y + 1 : U32))}, Pix{pixel(strokes, status, (x + 1 : U32), (y + 1 : U32))}}

def block4(+strokes: List<&2, Stroke>, +status: Hud.Status, +x: U32, +y: U32) -> Image:
  Qua{block2(strokes, status, x, y), block2(strokes, status, (x + 2 : U32), y),
    block2(strokes, status, x, (y + 2 : U32)), block2(strokes, status, (x + 2 : U32), (y + 2 : U32))}

def tiles(+depth: Nat, +strokes: List<&2, Stroke>, +status: Hud.Status,
  +x: U32, +y: U32, +size: U32) -> Image:
  match depth:
    case 0n:
      block4(filter(strokes, U32.to_f32(x), U32.to_f32(y), 4.0, []), status, x, y)
    case 1n+remaining:
      +half = (size / 2 : U32)
      a b c d = tiles(remaining, strokes, status, x, y, half)
        tiles(remaining, strokes, status, (x + half : U32), y, half)
        tiles(remaining, strokes, status, x, (y + half : U32), half)
        tiles(remaining, strokes, status, (x + half : U32), (y + half : U32), half)
      Qua{a, b, c, d}

def draw(cells: Cells, +status: Hud.Status, +x: U32, +y: U32, +size: U32) -> Image:
  match cells:
    case Cell{strokes}:
      tiles(3n, strokes, status, x, y, size)
    case Four{tl, tr, bl, br}:
      +half = (size / 2 : U32)
      a b c d = draw(tl, status, x, y, half) draw(tr, status, (x + half : U32), y, half)
        draw(bl, status, x, (y + half : U32), half)
        draw(br, status, (x + half : U32), (y + half : U32), half)
      Qua{a, b, c, d}

def frame(world: Simulation.World, +yaw: F32, trails: Bool, status: Hud.Status) -> Image:
  match world:
    case Simulation.World{particles, _}:
      scene = cells(4n, strokes(particles, Camera{F32.cos(yaw), F32.sin(yaw)}, trails, []), 0.0, 0.0, 512.0)
      draw!(scene, status, 0, 0, 512)
