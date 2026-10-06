import Base
import ./Grid.bend as Grid
import ../vortex/FloatTensor.bend as Tensor
import ../particles/Vector.bend as V

# RCCM-GfX-2 section 13.1, transverse vacuum subsystem, in c=1 units:
# e_t = -curl b, b_t = curl e.
# These signs follow A_0i=-e_i and A_ij=-epsilon_ijk b_k in the shared matrix.
# The axial/divergence convention is explicit in README.md. This is NOT a
# density/momentum/EOS, cavity-interface, gravity or charged-matter solver.
type World is Data:
  World{grid: Grid.Grid, steps: U32}

def generate(~sample: U32 -> U32 -> U32 -> U32 -> Grid.Cell,
  +depth: Nat, +offset: U32, +n: U32) -> Grid.Tree:
  match depth:
    case 0n:
      Grid.Leaf{sample(n, (offset % n : U32), (offset / n % n : U32), (offset / (n * n) : U32))}
    case 1n+remaining:
      +half = (1 << remaining : U32)
      a b = generate(~sample, remaining, offset, n) generate(~sample, remaining, (offset + half : U32), n)
      Grid.Fork{half, a, b}

# Internal constructor: depth means log2(side), not log2(total cell count).
# The interactive lab uses depth=4 (16^3); refinement checks use 8^3 and 16^3.
def make(~sample: U32 -> U32 -> U32 -> U32 -> Grid.Cell, +depth: Nat) -> Grid.Grid:
  +n = (1 << depth : U32)
  Grid.Grid{n, generate(~sample, Nat.add(depth, Nat.add(depth, depth)), 0, n)}

def rotate(axis: U32, vector: Tensor.Vector3) -> Tensor.Vector3:
  match axis vector:
    case 0 _:
      vector
    case 1 Tensor.Vector3{x, y, z}:
      Tensor.Vector3{z, x, y}
    case _ Tensor.Vector3{x, y, z}:
      Tensor.Vector3{y, z, x}

def coordinate(axis: U32, x: U32, y: U32, z: U32) -> U32:
  match axis:
    case 0:
      x
    case 1:
      y
    case _:
      z

# Analytic right-traveling, circularly polarized plane wave, sampled at the
# actual edge/face locations. Handedness is polarization, NOT electric charge.
def plane(+n: U32, x: U32, y: U32, z: U32, +time: F32, +axis: U32, +hand: F32) -> Grid.Cell:
  +phase = (6.283185307 * (U32.to_f32(coordinate(axis, x, y, z)) / U32.to_f32(n) - time) : F32)
  +face_phase = (phase + 3.141592654 / U32.to_f32(n) : F32)
  Grid.Cell{rotate(axis, Tensor.Vector3{0.0, (0.12 * F32.cos(phase) : F32), (hand * 0.12 * F32.sin(phase) : F32)}),
    rotate(axis, Tensor.Vector3{0.0, (hand * 0.12 * F32.sin(face_phase) : F32), (0.0 - 0.12 * F32.cos(face_phase) : F32)})}

def wave_x(n: U32, x: U32, y: U32, z: U32) -> Grid.Cell:
  plane(n, x, y, z, 0.0, 0, 1.0)

def wave_y(n: U32, x: U32, y: U32, z: U32) -> Grid.Cell:
  plane(n, x, y, z, 0.0, 1, (0.0 - 1.0 : F32))

def wave_z(n: U32, x: U32, y: U32, z: U32) -> Grid.Cell:
  plane(n, x, y, z, 0.0, 2, 1.0)

def waves(n: U32, x: U32, y: U32, z: U32) -> Grid.Cell:
  +n = n
  +x = x
  +y = y
  +z = z
  Grid.add(wave_x(n, x, y, z), Grid.add(wave_y(n, x, y, z), wave_z(n, x, y, z)))

def envelope(x: F32, y: F32, z: F32) -> F32:
  +s = (F32.sin((3.141592654 * x : F32)) * F32.sin((3.141592654 * y : F32)) *
    F32.sin((3.141592654 * z : F32)) : F32)
  (s * s * s * s : F32)

# Smooth periodic face potential. Taking its BACKWARD curl seeds e with
# div_minus(e)=0 by the same discrete identity used by the evolution.
def potential(+n: U32, x: U32, y: U32, z: U32) -> Tensor.Vector3:
  +h = (1.0 / U32.to_f32(n) : F32)
  +a = (U32.to_f32((x % n : U32)) * h : F32)
  +b = (U32.to_f32((y % n : U32)) * h : F32)
  +c = (U32.to_f32((z % n : U32)) * h : F32)
  Tensor.Vector3{
    (0.022 * envelope(a, (b + 0.5 * h : F32), (c + 0.5 * h : F32)) : F32),
    (0.033 * envelope((a + 0.5 * h : F32), b, (c + 0.5 * h : F32)) : F32),
    (0.044 * envelope((a + 0.5 * h : F32), (b + 0.5 * h : F32), c) : F32)}

def pulse(n: U32, x: U32, y: U32, z: U32) -> Grid.Cell:
  +n = n
  +x = x
  +y = y
  +z = z
  +here = potential(n, x, y, z)
  Grid.Cell{V.scale(U32.to_f32(n), Grid.curl_components(
    V.sub(here, potential(n, (x + n - 1 : U32), y, z)),
    V.sub(here, potential(n, x, (y + n - 1 : U32), z)),
    V.sub(here, potential(n, x, y, (z + n - 1 : U32))))), V.zero()}

def uniform(n: U32, x: U32, y: U32, z: U32) -> Grid.Cell:
  Grid.Cell{Tensor.Vector3{0.12, 0.0, 0.0}, Tensor.Vector3{0.0, 0.12, 0.0}}

def initial(seed: U32) -> World:
  match seed:
    case 1:
      World{make(~pulse, 4n), 0}
    case 2:
      World{make(~uniform, 4n), 0}
    case _:
      World{make(~waves, 4n), 0}

def update_cell(rotation: Bool, cell: Grid.Cell, curl: Tensor.Vector3, dt: F32) -> Grid.Cell:
  match rotation cell:
    case True{} Grid.Cell{e, b}:
      Grid.Cell{e, V.add(b, V.scale(dt, curl))}
    case False{} Grid.Cell{e, b}:
      Grid.Cell{V.sub(e, V.scale(dt, curl)), b}

def update_tree(tree: Grid.Tree, +source: Grid.Grid, +n: U32, +offset: U32,
  +rotation: Bool, +dt: F32) -> Grid.Tree:
  match tree:
    case Grid.Leaf{cell}:
      Grid.Leaf{update_cell(rotation, cell,
        Grid.curl(source, Bool.not(rotation), rotation,
          (offset % n : U32), (offset / n % n : U32), (offset / (n * n) : U32)), dt)}
    case Grid.Fork{+half, left, right}:
      a b = update_tree(left, source, n, offset, rotation, dt)
        update_tree(right, source, n, (offset + half : U32), rotation, dt)
      Grid.Fork{half, a, b}

def update(+grid: Grid.Grid, rotation: Bool, dt: F32) -> Grid.Grid:
  Grid.Grid{+n, cells} = grid
  Grid.Grid{n, update_tree(cells, grid, n, 0, rotation, dt)}

# Symmetric kick-drift-kick. Both fields are synchronized at each full step.
# No prescribed time-dependent fields, trap, damping, speed cap, or pair force.
def integrate(grid: Grid.Grid, +dt: F32) -> Grid.Grid:
  first = update(grid, True{}, (0.5 * dt : F32))
  second = update(first, False{}, dt)
  update(second, True{}, (0.5 * dt : F32))

def timestep(grid: Grid.Grid) -> F32:
  match grid:
    case Grid.Grid{n, _}:
      (0.4 / U32.to_f32(n) : F32)

# For the 3D Yee operator: c dt/dx <= 1/sqrt(3). Use a slightly conservative
# limit here; the fixed public step uses 0.4. NaNs fail the comparisons.
def allowed_dt(grid: Grid.Grid, +dt: F32) -> Bool:
  match grid:
    case Grid.Grid{n, _}:
      (dt > 0.0 : F32) && (dt * U32.to_f32(n) <= 0.57735 : F32)

def advance_allowed(valid: Bool, grid: Grid.Grid, dt: F32) -> Maybe<Grid.Grid>:
  match valid:
    case False{}:
      None{}
    case True{}:
      Some{integrate(grid, dt)}

def advance(+grid: Grid.Grid, +dt: F32) -> Maybe<Grid.Grid>:
  advance_allowed(allowed_dt(grid, dt), grid, dt)

def step(world: World) -> World:
  match world:
    case World{+grid, steps}:
      World{integrate(grid, timestep(grid)), (steps + 1 : U32)}

def evolve(fuel: Nat, world: World) -> World:
  match fuel:
    case 0n:
      world
    case 1n+remaining:
      evolve(remaining, step(world))

def time(world: World) -> F32:
  match world:
    case World{grid, steps}:
      (U32.to_f32(steps) * timestep(grid) : F32)
