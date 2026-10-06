import Base
import ./Grid.bend as Grid
import ./Diagnostics.bend as Diag
import ./Simulation.bend as Sim
import ./Controls.bend as Controls
import ./Hud.bend as Hud
import ../vortex/FloatTensor.bend as Tensor
import ../vortex/Math.bend as Math
import ../tensor/Matrix4.bend as Matrix

type Panels is Data:
  Panels{xy: Image, xz: Image, yz: Image, tensor: Image, slice: U32, mode: U32}

def signed(value: F32, range: F32) -> U32:
  +v = Math.clamp((value / range : F32), (0.0 - 1.0 : F32), 1.0)
  +a = F32.abs(v)
  Math.pack((0.12 + Math.max(v, 0.0) * 0.72 : F32),
    (0.16 + a * 0.45 : F32), (0.20 + Math.max((0.0 - v : F32), 0.0) * 0.62 : F32))

def field_color(mode: U32, cell: Grid.Cell) -> U32:
  match mode cell:
    case 0 Grid.Cell{Tensor.Vector3{_, _, z}, _}:
      signed(z, 0.5)
    case 1 Grid.Cell{_, Tensor.Vector3{_, _, z}}:
      signed(z, 0.5)
    case _ _:
      +p = Math.clamp(Diag.load(cell), 0.0, 1.0)
      Math.pack((0.08 + 0.8 * p : F32), (0.13 + 0.6 * p : F32), (0.18 + 0.15 * p : F32))

def sample(plane: U32, grid: Grid.Grid, s: U32, a: U32, b: U32) -> Grid.Cell:
  match plane:
    case 0:
      Grid.centered(grid, a, b, s)
    case 1:
      Grid.centered(grid, a, s, b)
    case _:
      Grid.centered(grid, s, a, b)

# Host reconstruction: only 3*16*16 samples, not a grid walk per pixel.
def plane(+depth: Nat, +grid: Grid.Grid, +s: U32, +mode: U32, +axis: U32,
  +x: U32, +y: U32, +size: U32) -> Image:
  match depth:
    case 0n:
      Pix{field_color(mode, sample(axis, grid, s, x, y))}
    case 1n+rest:
      +half = (size / 2 : U32)
      a b c d = plane(rest, grid, s, mode, axis, x, y, half)
        plane(rest, grid, s, mode, axis, (x + half : U32), y, half)
        plane(rest, grid, s, mode, axis, x, (y + half : U32), half)
        plane(rest, grid, s, mode, axis, (x + half : U32), (y + half : U32), half)
      Qua{a, b, c, d}

def row(row: Matrix.Row4<F32>) -> Image:
  match row:
    case Matrix.Row4{a, b, c, d}:
      # Include the >1 spatial diagonals instead of saturating every one of them.
      Qua{Pix{signed(a, 2.0)}, Pix{signed(b, 2.0)}, Pix{signed(c, 2.0)}, Pix{signed(d, 2.0)}}

def matrix(matrix: Maybe<Matrix.Matrix4<F32>>) -> Image:
  match matrix:
    case None{}:
      Pix{13998706}
    case Some{Matrix.Matrix4{
      Matrix.Row4{a, b, c, d}, Matrix.Row4{e, f, g, h},
      Matrix.Row4{i, j, k, l}, Matrix.Row4{m, n, o, p}}}:
      Qua{row(Matrix.Row4{a, b, e, f}), row(Matrix.Row4{c, d, g, h}),
        row(Matrix.Row4{i, j, m, n}), row(Matrix.Row4{k, l, o, p})}

def panels(scene: Controls.Scene) -> Panels:
  match scene:
    case Controls.Scene{Sim.World{+grid, _}, _, _, _, _, +s, +mode, _}:
      xy xz yz t = plane(4n, grid, s, mode, 0, 0, 0, 16)
        plane(4n, grid, s, mode, 1, 0, 0, 16)
        plane(4n, grid, s, mode, 2, 0, 0, 16)
        matrix(Diag.tensor(Grid.centered(grid, s, s, s)))
      Panels{xy, xz, yz, t, s, mode}

# Tail-only lookup into small precolored image trees. Bool selectors are
# parameters so recursive calls visibly descend into a strict image subtree.
def lookup_bits(image: Image, +x: U32, +y: U32, +half: U32,
  right: Bool, bottom: Bool) -> U32:
  match image right bottom:
    case Pix{color} _ _:
      color
    case Qua{a, _, _, _} False{} False{}:
      lookup_bits(a, (x % half : U32), (y % half : U32), (half / 2 : U32),
        (x % half >= half / 2 : U32), (y % half >= half / 2 : U32))
    case Qua{_, b, _, _} True{} False{}:
      lookup_bits(b, (x % half : U32), (y % half : U32), (half / 2 : U32),
        (x % half >= half / 2 : U32), (y % half >= half / 2 : U32))
    case Qua{_, _, c, _} False{} True{}:
      lookup_bits(c, (x % half : U32), (y % half : U32), (half / 2 : U32),
        (x % half >= half / 2 : U32), (y % half >= half / 2 : U32))
    case Qua{_, _, _, d} True{} True{}:
      lookup_bits(d, (x % half : U32), (y % half : U32), (half / 2 : U32),
        (x % half >= half / 2 : U32), (y % half >= half / 2 : U32))

def lookup(image: Image, +x: U32, +y: U32, +size: U32) -> U32:
  lookup_bits(image, x, y, (size / 2 : U32), (x >= size / 2 : U32), (y >= size / 2 : U32))

def slice_pixel(image: Image, +s: U32, +x: U32, +y: U32) -> U32:
  +mark = (U32.is_eq(x, (s * 11 + 5 : U32)) ||
    U32.is_eq(y, (s * 11 + 5 : U32))) &&
    (U32.is_eq((x % 11 : U32), 5) || U32.is_eq((y % 11 : U32), 5))
  Math.word(mark, 15657180, lookup(image, (x / 11 : U32), (y / 11 : U32), 16))

def tensor_pixel(inside: Bool, image: Image, +x: U32, +y: U32) -> U32:
  match inside:
    case False{}:
      527635
    case True{}:
      Math.word(U32.is_eq(((x - 264) % 32 : U32), 0) || U32.is_eq(((y - 300) % 32 : U32), 0),
        2503740, lookup(image, ((x - 264) / 32 : U32), ((y - 300) / 32 : U32), 4))

def body_region(left: Bool, right: Bool, top: Bool, bottom: Bool,
  xy: Image, xz: Image, yz: Image, tensor: Image, s: U32, +x: U32, +y: U32) -> U32:
  match left right top bottom:
    case True{} _ True{} _:
      slice_pixel(xy, s, (x - 24 : U32), (y - 102 : U32))
    case _ True{} True{} _:
      slice_pixel(xz, s, (x - 264 : U32), (y - 102 : U32))
    case True{} _ _ True{}:
      slice_pixel(yz, s, (x - 24 : U32), (y - 300 : U32))
    case _ True{} _ True{}:
      tensor_pixel((y < 428 : U32) && (x < 392 : U32), tensor, x, y)
    case _ _ _ _:
      527635

def legend(mode: U32, +y: U32) -> U32:
  match mode:
    case 2:
      +p = ((277.0 - U32.to_f32(y)) / 175.0 : F32)
      Math.pack((0.08 + 0.8 * p : F32), (0.13 + 0.6 * p : F32), (0.18 + 0.15 * p : F32))
    case _:
      signed(((277.0 - U32.to_f32(y)) / 175.0 - 0.5 : F32), 0.5)

def body_or_legend(is_legend: Bool, mode: U32, xy: Image, xz: Image, yz: Image,
  tensor: Image, s: U32, +x: U32, +y: U32) -> U32:
  match is_legend:
    case True{}:
      legend(mode, y)
    case False{}:
      body_region((x >= 24 : U32) && (x < 200 : U32),
        (x >= 264 : U32) && (x < 440 : U32),
        (y >= 102 : U32) && (y < 278 : U32),
        (y >= 300 : U32) && (y < 476 : U32),
        xy, xz, yz, tensor, s, x, y)

def body(panels: Panels, +x: U32, +y: U32) -> U32:
  match panels:
    case Panels{xy, xz, yz, tensor, s, mode}:
      body_or_legend((x >= 460 : U32) && (x < 472 : U32) &&
        (y >= 102 : U32) && (y < 278 : U32), mode, xy, xz, yz, tensor, s, x, y)

def pixel(+panels: Panels, labels: Hud.Labels, +x: U32, +y: U32) -> U32:
  +overlay = Hud.color(labels, x, y)
  Math.word(U32.is_eq(overlay, 0), body(panels, x, y), overlay)

def block2(+panels: Panels, +labels: Hud.Labels, +x: U32, +y: U32) -> Image:
  Qua{Pix{pixel(panels, labels, x, y)}, Pix{pixel(panels, labels, (x + 1 : U32), y)},
    Pix{pixel(panels, labels, x, (y + 1 : U32))},
    Pix{pixel(panels, labels, (x + 1 : U32), (y + 1 : U32))}}

def block4(+panels: Panels, +labels: Hud.Labels, +x: U32, +y: U32) -> Image:
  Qua{block2(panels, labels, x, y), block2(panels, labels, (x + 2 : U32), y),
    block2(panels, labels, x, (y + 2 : U32)),
    block2(panels, labels, (x + 2 : U32), (y + 2 : U32))}

def tiles(+depth: Nat, +panels: Panels, +labels: Hud.Labels,
  +x: U32, +y: U32, +size: U32) -> Image:
  match depth:
    case 0n:
      block4(panels, labels, x, y)
    case 1n+rest:
      +half = (size / 2 : U32)
      a b c d = tiles(rest, panels, labels, x, y, half)
        tiles(rest, panels, labels, (x + half : U32), y, half)
        tiles(rest, panels, labels, x, (y + half : U32), half)
        tiles(rest, panels, labels, (x + half : U32), (y + half : U32), half)
      Qua{a, b, c, d}

def frame(+scene: Controls.Scene) -> Image:
  tiles!(7n, panels(scene), Hud.labels(scene), 0, 0, 512)
