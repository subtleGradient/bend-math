import Base
import ../vortex/FloatTensor.bend as Tensor
import ../particles/Vector.bend as V

# Periodic unit cube. Six DOFs per lattice site, NOT six collocated samples.
# e = v_perp/c lives on edges; b = t_p Omega lives on faces (Yee staggering).
# e_x: (i+.5,j,k), b_x: (i,j+.5,k+.5); cyclic permutations for y,z.
type Cell is Data:
  Cell{slip: Tensor.Vector3, rotation: Tensor.Vector3}

type Tree is Data:
  Leaf{value: Cell}
  Fork{half: U32, left: Tree, right: Tree}

type Grid is Data:
  Grid{side: U32, cells: Tree}

def zero() -> Cell:
  Cell{V.zero(), V.zero()}

def add(left: Cell, right: Cell) -> Cell:
  match left right:
    case Cell{e, b} Cell{f, g}:
      Cell{V.add(e, f), V.add(b, g)}

def scale(+factor: F32, cell: Cell) -> Cell:
  match cell:
    case Cell{e, b}:
      Cell{V.scale(factor, e), V.scale(factor, b)}

def field(rotation: Bool, cell: Cell) -> Tensor.Vector3:
  match rotation cell:
    case False{} Cell{e, _}:
      e
    case True{} Cell{_, b}:
      b

def index(+n: U32, x: U32, y: U32, z: U32) -> U32:
  (x % n + n * (y % n) + n * n * (z % n) : U32)

def lookup(tree: Tree, +i: U32, lower: Bool) -> Cell:
  match tree lower:
    case Leaf{value} _:
      value
    case Fork{+half, left, _} True{}:
      lookup(left, i, (i < half / 2 : U32))
    case Fork{+half, _, right} False{}:
      +j = (i - half : U32)
      lookup(right, j, (j < half / 2 : U32))

def at(grid: Grid, x: U32, y: U32, z: U32) -> Cell:
  match grid:
    case Grid{+n, cells}:
      +i = index(n, x, y, z)
      lookup(cells, i, (i < n * n * n / 2 : U32))

def next(forward: Bool, +n: U32, i: U32) -> U32:
  match forward:
    case True{}:
      ((i + 1) % n : U32)
    case False{}:
      ((i + n - 1) % n : U32)

def difference(forward: Bool, neighbor: Tensor.Vector3, here: Tensor.Vector3) -> Tensor.Vector3:
  match forward:
    case True{}:
      V.sub(neighbor, here)
    case False{}:
      V.sub(here, neighbor)

def curl_components(dx: Tensor.Vector3, dy: Tensor.Vector3, dz: Tensor.Vector3) -> Tensor.Vector3:
  match dx dy dz:
    case Tensor.Vector3{_, xy, xz} Tensor.Vector3{yx, _, yz} Tensor.Vector3{zx, zy, _}:
      Tensor.Vector3{(yz - zy : F32), (zx - xz : F32), (xy - yx : F32)}

def divergence_components(dx: Tensor.Vector3, dy: Tensor.Vector3, dz: Tensor.Vector3) -> F32:
  match dx dy dz:
    case Tensor.Vector3{x, _, _} Tensor.Vector3{_, y, _} Tensor.Vector3{_, _, z}:
      (x + y + z : F32)

# Templates share the stencil between curl and divergence without storing
# closures in the lattice. All neighbors come from ONE immutable grid snapshot.
def derivative(~R: Data, ~combine: Tensor.Vector3 -> Tensor.Vector3 -> Tensor.Vector3 -> R,
  +grid: Grid, +rotation: Bool, +forward: Bool, +x: U32, +y: U32, +z: U32) -> R:
  Grid{+n, _} = grid
  +here = field(rotation, at(grid, x, y, z))
  +factor = U32.to_f32(n)
  dx = V.scale(factor, difference(forward, field(rotation, at(grid, next(forward, n, x), y, z)), here))
  dy = V.scale(factor, difference(forward, field(rotation, at(grid, x, next(forward, n, y), z)), here))
  dz = V.scale(factor, difference(forward, field(rotation, at(grid, x, y, next(forward, n, z))), here))
  combine(dx, dy, dz)

def curl(grid: Grid, rotation: Bool, forward: Bool, x: U32, y: U32, z: U32) -> Tensor.Vector3:
  derivative(~Tensor.Vector3, ~curl_components, grid, rotation, forward, x, y, z)

def divergence(grid: Grid, rotation: Bool, forward: Bool, x: U32, y: U32, z: U32) -> F32:
  derivative(~F32, ~divergence_components, grid, rotation, forward, x, y, z)

def average_faces(here: Tensor.Vector3, dx: Tensor.Vector3, dy: Tensor.Vector3, dz: Tensor.Vector3) -> Tensor.Vector3:
  match here dx dy dz:
    case Tensor.Vector3{x, y, z} Tensor.Vector3{a, _, _} Tensor.Vector3{_, b, _} Tensor.Vector3{_, _, c}:
      Tensor.Vector3{((x + a) * 0.5 : F32), ((y + b) * 0.5 : F32), ((z + c) * 0.5 : F32)}

def average_edges(a: Tensor.Vector3, b: Tensor.Vector3, c: Tensor.Vector3,
  d: Tensor.Vector3, e: Tensor.Vector3, f: Tensor.Vector3, g: Tensor.Vector3) -> Tensor.Vector3:
  match a b c d e f g:
    case Tensor.Vector3{ax, ay, az} Tensor.Vector3{_, by, bz} Tensor.Vector3{cx, _, cz}
      Tensor.Vector3{dx, dy, _} Tensor.Vector3{_, _, ez} Tensor.Vector3{_, fy, _} Tensor.Vector3{gx, _, _}:
      Tensor.Vector3{((ax + cx + dx + gx) * 0.25 : F32),
        ((ay + by + dy + fy) * 0.25 : F32), ((az + bz + cz + ez) * 0.25 : F32)}

# Reconstruct a collocated value at (i+.5,j+.5,k+.5) for display/tensor ONLY.
# Never use this smoothed reconstruction for the stencil or lattice energy.
def centered(+grid: Grid, +x: U32, +y: U32, +z: U32) -> Cell:
  +a = at(grid, x, y, z)
  +b = at(grid, (x + 1 : U32), y, z)
  +c = at(grid, x, (y + 1 : U32), z)
  +d = at(grid, x, y, (z + 1 : U32))
  Cell{average_edges(field(False{}, a), field(False{}, b), field(False{}, c), field(False{}, d),
      field(False{}, at(grid, (x + 1 : U32), (y + 1 : U32), z)),
      field(False{}, at(grid, (x + 1 : U32), y, (z + 1 : U32))),
      field(False{}, at(grid, x, (y + 1 : U32), (z + 1 : U32)))),
    average_faces(field(True{}, a), field(True{}, b), field(True{}, c), field(True{}, d))}
