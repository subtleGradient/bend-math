import Base
import ./Grid.bend as Grid
import ./Simulation.bend as Sim
import ../particles/Vector.bend as V
import ../vortex/Math.bend as Math
import ../vortex/FloatTensor.bend as Tensor
import ../tensor/Matrix4.bend as Matrix4

type Stats is Data:
  Stats{energy: F32, invariant: F32, div_slip: F32, div_rotation: F32,
    peak_load: F32, finite: Bool}

# The norm below is the numerical transverse-system energy, NOT the paper's
# full thermodynamic energy. Components are summed on their own staggered DOFs.
def energy(cell: Grid.Cell) -> F32:
  match cell:
    case Grid.Cell{e, b}:
      (0.5 * (V.length_squared(e) + V.length_squared(b)) : F32)

def finite_vector(vector: Tensor.Vector3) -> Bool:
  match vector:
    case Tensor.Vector3{x, y, z}:
      (F32.abs(x) < 1.0e15 : F32) && (F32.abs(y) < 1.0e15 : F32) && (F32.abs(z) < 1.0e15 : F32)

def finite(cell: Grid.Cell) -> Bool:
  match cell:
    case Grid.Cell{e, b}:
      finite_vector(e) && finite_vector(b)

# Transverse-only pressure diagnostic: Pdyn/Pc = |v_perp/c|^2.
# Omits longitudinal, background, rotational and shear loads; NOT an EOS.
def load(cell: Grid.Cell) -> F32:
  V.length_squared(Grid.field(False{}, cell))

def capacity(cell: Grid.Cell) -> F32:
  (1.0 - load(cell) : F32)

def tensor_allowed(valid: Bool, cell: Grid.Cell) -> Maybe<Matrix4.Matrix4<F32>>:
  match valid cell:
    case False{} _:
      None{}
    case True{} Grid.Cell{+e, b}:
      Some{Tensor.matrix(F32.sqrt((1.0 - V.length_squared(e) : F32)), 1.0, 1.0, 1.0, e, b)}

# Diagnostic reconstruction with alpha=c=t_p=1. The shared paper matrix layout
# is not a force law and is never used as a substitute for the PDE update.
# No pressure floor or finite fake matrix is supplied at zero/negative capacity.
def tensor(+cell: Grid.Cell) -> Maybe<Matrix4.Matrix4<F32>>:
  tensor_allowed(finite(cell) && (capacity(cell) > 0.0 : F32), cell)

def combine(left: Stats, right: Stats) -> Stats:
  match left right:
    case Stats{e, h, d, r, p, ok} Stats{f, k, a, b, q, good}:
      Stats{(e + f : F32), (h + k : F32), Math.max(d, a), Math.max(r, b), Math.max(p, q), ok && good}

def measure_tree(tree: Grid.Tree, +source: Grid.Grid, +n: U32, +offset: U32, +dt: F32) -> Stats:
  match tree:
    case Grid.Leaf{+cell}:
      +x = (offset % n : U32)
      +y = (offset / n % n : U32)
      +z = (offset / (n * n) : U32)
      +e = energy(cell)
      # KDK preserves H = 1/2 (|b|^2 + |e|^2 - dt^2/4 |curl_plus e|^2)
      # in exact arithmetic with periodic boundaries. F32 checks are regressions.
      h = (e - 0.125 * dt * dt * V.length_squared(Grid.curl(source, False{}, True{}, x, y, z)) : F32)
      Stats{e, h,
        F32.abs(Grid.divergence(source, False{}, False{}, x, y, z)),
        F32.abs(Grid.divergence(source, True{}, True{}, x, y, z)),
        load(Grid.centered(source, x, y, z)), finite(cell)}
    case Grid.Fork{half, left, right}:
      a b = measure_tree(left, source, n, offset, dt)
        measure_tree(right, source, n, (offset + half : U32), dt)
      combine(a, b)

def normalize(stats: Stats, +volume: F32) -> Stats:
  match stats:
    case Stats{energy, invariant, de, db, peak, finite}:
      Stats{(energy * volume : F32), (invariant * volume : F32), de, db, peak, finite}

def measure_at(+grid: Grid.Grid, dt: F32) -> Stats:
  Grid.Grid{+n, cells} = grid
  normalize(measure_tree(cells, grid, n, 0, dt),
    (1.0 / U32.to_f32((n * n * n : U32)) : F32))

# Default-step wrapper for Sim.step. A custom constant-dt run must use
# measure_at(grid, actual_dt); changing dt does not preserve one fixed H.
def measure(+grid: Grid.Grid) -> Stats:
  measure_at(grid, Sim.timestep(grid))

def admissible(stats: Stats) -> Bool:
  match stats:
    case Stats{_, _, _, _, peak, finite}:
      finite && (peak < 1.0 : F32)
