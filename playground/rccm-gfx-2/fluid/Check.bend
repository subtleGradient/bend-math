import Base
import ./Grid.bend as Grid
import ./Simulation.bend as Sim
import ./Diagnostics.bend as Diag
import ../vortex/FloatTensor.bend as Tensor
import ../tensor/Matrix4.bend as Matrix4
import ../particles/Vector.bend as V
import ../vortex/Math.bend as Math

# Runtime numerical regressions, NOT formal proofs or physical validation.
def expect(ok: Bool, +label: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("PASS " ++ label)
    case False{}:
      IO.die(Unit, 1, "FAIL " ++ label)

def near(x: F32, y: F32, tolerance: F32) -> Bool:
  (F32.abs((x - y : F32)) <= tolerance : F32)

def cell_error(a: Grid.Cell, b: Grid.Cell) -> F32:
  match a b:
    case Grid.Cell{e, b} Grid.Cell{f, c}:
      (V.length_squared(V.sub(e, f)) + V.length_squared(V.sub(b, c)) : F32)

def grid_of(world: Sim.World) -> Grid.Grid:
  match world:
    case Sim.World{grid, _}:
      grid

def count(tree: Grid.Tree) -> U32:
  match tree:
    case Grid.Leaf{_}:
      1
    case Grid.Fork{_, left, right}:
      (count(left) + count(right) : U32)

def xyz(n: U32, x: U32, y: U32, z: U32) -> Grid.Cell:
  +v = {Tensor.Vector3{U32.to_f32(x), U32.to_f32(y), U32.to_f32(z)} : Tensor.Vector3}
  Grid.Cell{v, v}

def transverse_xyz(n: U32, x: U32, y: U32, z: U32) -> Grid.Cell:
  +a = U32.to_f32(x)
  +b = U32.to_f32(y)
  +c = U32.to_f32(z)
  Grid.Cell{Tensor.Vector3{(b + 2.0 * c : F32), (a + 2.0 * c : F32), (a + 2.0 * b : F32)}, V.zero()}

def zero(n: U32, x: U32, y: U32, z: U32) -> Grid.Cell:
  Grid.zero()

def rough(n: U32, x: U32, y: U32, z: U32) -> Grid.Cell:
  +i = Grid.index(n, x, y, z)
  Grid.Cell{Tensor.Vector3{(0.03 * U32.to_f32((i % 7 : U32)) : F32),
      (0.02 * U32.to_f32((i % 11 : U32)) : F32), (0.01 * U32.to_f32((i % 13 : U32)) : F32)},
    Tensor.Vector3{(0.01 * U32.to_f32((i % 17 : U32)) : F32),
      (0.015 * U32.to_f32((i % 19 : U32)) : F32), (0.02 * U32.to_f32((i % 5 : U32)) : F32)}}

def difference_tree(a: Grid.Tree, b: Grid.Tree) -> F32:
  match a b:
    case Grid.Leaf{x} Grid.Leaf{y}:
      cell_error(x, y)
    case Grid.Fork{_, a, b} Grid.Fork{_, c, d}:
      (difference_tree(a, c) + difference_tree(b, d) : F32)
    case _ _:
      1.0e20

def difference(a: Grid.Grid, b: Grid.Grid) -> F32:
  match a b:
    case Grid.Grid{_, a} Grid.Grid{_, b}:
      difference_tree(a, b)

def cell_count(grid: Grid.Grid) -> U32:
  match grid:
    case Grid.Grid{_, tree}:
      count(tree)

def topology_checks() -> IO(Unit):
  +grid = Sim.make(~xyz, 3n)
  +transverse = Sim.make(~transverse_xyz, 3n)
  +uniform = Sim.make(~Sim.uniform, 3n)
  +empty = Sim.make(~zero, 3n)
  do IO<Unit>:
    expect(U32.is_eq(cell_count(grid), 512), "all 8^3 cells exist")
    expect(near(cell_error(Grid.at(grid, 7, 6, 5), xyz(8, 7, 6, 5)), 0.0, 0.0), "3D indexing does not collapse an axis")
    expect(near(cell_error(Grid.at(grid, 8, 9, 10), xyz(8, 0, 1, 2)), 0.0, 0.0), "each periodic axis wraps independently")
    expect(U32.is_eq(Grid.next(False{}, 8, 0), 7), "backward stencil wraps at zero")
    expect(near(cell_error(Grid.centered(grid, 2, 3, 4),
      Grid.Cell{Tensor.Vector3{2.0, 3.0, 4.0}, Tensor.Vector3{2.5, 3.5, 4.5}}), 0.0, 0.0),
      "edge and face reconstruction use their actual staggered positions")
    expect(near(cell_error(Grid.centered(transverse, 2, 3, 4),
      Grid.Cell{Tensor.Vector3{12.5, 11.5, 9.5}, V.zero()}), 0.0, 0.0),
      "edge reconstruction averages both transverse directions")
    expect(near(cell_error(Grid.centered(transverse, 7, 7, 7),
      Grid.Cell{Tensor.Vector3{10.5, 10.5, 10.5}, V.zero()}), 0.0, 0.0),
      "center reconstruction crosses all periodic seams correctly")
    expect(near(difference(uniform, grid_of(Sim.evolve(40n, Sim.World{uniform, 0}))), 0.0, 0.0), "uniform state is an exact equilibrium")
    expect(near(difference(empty, grid_of(Sim.evolve(20n, Sim.World{empty, 0}))), 0.0, 0.0), "zero state does not generate motion")
    expect(Sim.allowed_dt(grid, 0.05) && Bool.not(Sim.allowed_dt(grid, 0.1)), "3D CFL gate accepts fixed step and rejects oversized step")
    expect(Bool.not(Sim.allowed_dt(grid, 0.0)) && Bool.not(Sim.allowed_dt(grid, (0.0 - 0.05 : F32))) &&
      Bool.not(Sim.allowed_dt(grid, (0.0 / 0.0 : F32))), "invalid timesteps are rejected")

# Summation by parts over a deliberately rough, non-divergence-free fixture:
# <b,curl_plus e> = <e,curl_minus b>, including every periodic seam.
def adjoint_tree(tree: Grid.Tree, +grid: Grid.Grid, +n: U32, +offset: U32) -> F32:
  match tree:
    case Grid.Leaf{Grid.Cell{e, b}}:
      +x = (offset % n : U32)
      +y = (offset / n % n : U32)
      +z = (offset / (n * n) : U32)
      (V.dot(b, Grid.curl(grid, False{}, True{}, x, y, z)) -
        V.dot(e, Grid.curl(grid, True{}, False{}, x, y, z)) : F32)
    case Grid.Fork{half, left, right}:
      (adjoint_tree(left, grid, n, offset) + adjoint_tree(right, grid, n, (offset + half : U32)) : F32)

def divergence_change(tree: Grid.Tree, +a: Grid.Grid, +b: Grid.Grid, +n: U32, +offset: U32) -> F32:
  match tree:
    case Grid.Leaf{_}:
      +x = (offset % n : U32)
      +y = (offset / n % n : U32)
      +z = (offset / (n * n) : U32)
      Math.max(F32.abs((Grid.divergence(a, False{}, False{}, x, y, z) -
          Grid.divergence(b, False{}, False{}, x, y, z) : F32)),
        F32.abs((Grid.divergence(a, True{}, True{}, x, y, z) -
          Grid.divergence(b, True{}, True{}, x, y, z) : F32)))
    case Grid.Fork{half, left, right}:
      Math.max(divergence_change(left, a, b, n, offset),
        divergence_change(right, a, b, n, (offset + half : U32)))

def operator_report(grid: Grid.Grid, after: Grid.Grid, initial: Diag.Stats, final: Diag.Stats) -> IO(Unit):
  match grid initial final:
    case Grid.Grid{+n, +tree} Diag.Stats{_, h0, _, _, _, _} Diag.Stats{_, h1, _, _, _, valid}:
      +source = {Grid.Grid{n, tree} : Grid.Grid}
      do IO<Unit>:
        expect(near(adjoint_tree(tree, source, n, 0), 0.0, 0.00005), "forward/backward curls are discrete adjoints")
        expect((divergence_change(tree, source, after, n, 0) < 0.00005 : F32), "both divergences preserve nonzero initial constraints")
        expect(valid && near((h1 / h0 : F32), 1.0, 0.00002), "rough 3D state preserves modified KDK energy")

def operator_checks() -> IO(Unit):
  +grid = Sim.make(~rough, 3n)
  +after = grid_of(Sim.evolve(40n, Sim.World{grid, 0}))
  operator_report(grid, after, Diag.measure(grid), Diag.measure(after))

def slip_z(n: U32, x: U32, y: U32, z: U32) -> Grid.Cell:
  Grid.Cell{Tensor.Vector3{0.0, 0.0, F32.sin((6.283185307 * U32.to_f32(y) / U32.to_f32(n) : F32))}, V.zero()}

def rotation_z(n: U32, x: U32, y: U32, z: U32) -> Grid.Cell:
  Grid.Cell{V.zero(), Tensor.Vector3{0.0, 0.0, F32.sin((6.283185307 * U32.to_f32(y) / U32.to_f32(n) : F32))}}

def x_component(vector: Tensor.Vector3) -> F32:
  match vector:
    case Tensor.Vector3{x, _, _}:
      x

# Independent component probes, not only plane waves whose initial b could
# accidentally mask a simultaneous reversal of BOTH evolution signs.
def orientation_checks() -> IO(Unit):
  +e = Sim.make(~slip_z, 3n)
  +b = Sim.make(~rotation_z, 3n)
  +expected = (0.4 * F32.sin((3.141592654 / 4.0 : F32)) : F32)
  do IO<Unit>:
    expect(near(x_component(Grid.field(True{}, Grid.at(Sim.update(e, True{}, 0.05), 2, 0, 1))), expected, 0.000001),
      "Bianchi identity with A_yz=-b_x gives positive b_x from positive d_y e_z")
    expect(near(x_component(Grid.field(False{}, Grid.at(Sim.update(b, False{}, 0.05), 2, 0, 1))),
      (0.0 - expected : F32), 0.000001),
      "raised spacetime divergence with A_0x=-e_x gives negative e_x from positive d_y b_z")

def invariant(stats: Diag.Stats) -> F32:
  match stats:
    case Diag.Stats{_, h, _, _, _, _}:
      h

def custom_report(before: Grid.Grid, +dt: F32, advanced: Maybe<Grid.Grid>) -> IO(Unit):
  match advanced:
    case None{}:
      expect(False{}, "custom stable timestep is accepted")
    case Some{after}:
      h0 = invariant(Diag.measure_at(before, dt))
      h1 = invariant(Diag.measure_at(after, dt))
      expect(near((h1 / h0 : F32), 1.0, 0.000001), "invariant uses the actual nondefault constant timestep")

def custom_step_checks() -> IO(Unit):
  +grid = Sim.make(~slip_z, 3n)
  custom_report(grid, 0.025, Sim.advance(grid, 0.025))

type Error is Data:
  Error{square: F32, maximum: F32}

def max_component(v: Tensor.Vector3) -> F32:
  match v:
    case Tensor.Vector3{x, y, z}:
      Math.max(F32.abs(x), Math.max(F32.abs(y), F32.abs(z)))

def error(a: Grid.Cell, b: Grid.Cell) -> Error:
  match a b:
    case Grid.Cell{e, b} Grid.Cell{f, c}:
      +de = V.sub(e, f)
      +db = V.sub(b, c)
      Error{(V.length_squared(de) + V.length_squared(db) : F32),
        Math.max(max_component(de), max_component(db))}

def combine_error(a: Error, b: Error) -> Error:
  match a b:
    case Error{s, m} Error{t, n}:
      Error{(s + t : F32), Math.max(m, n)}

# Independent oblique analytic mode: k=2pi(1,1,1), polarization (1,-1,0)/sqrt(2),
# b=-k_hat cross e. Sample every component at its own Yee location.
def oblique(+n: U32, x: U32, y: U32, z: U32, +t: F32) -> Grid.Cell:
  +s = U32.to_f32((x + y + z : U32))
  +edge = F32.cos((6.283185307 * ((s + 0.5) / U32.to_f32(n) - F32.sqrt(3.0) * t) : F32))
  +face = F32.cos((6.283185307 * ((s + 1.0) / U32.to_f32(n) - F32.sqrt(3.0) * t) : F32))
  +e = (0.12 * edge / F32.sqrt(2.0) : F32)
  +b = (0.12 * face / F32.sqrt(6.0) : F32)
  Grid.Cell{Tensor.Vector3{e, (0.0 - e : F32), 0.0},
    Tensor.Vector3{(0.0 - b : F32), (0.0 - b : F32), (2.0 * b : F32)}}

def oblique_seed(n: U32, x: U32, y: U32, z: U32) -> Grid.Cell:
  oblique(n, x, y, z, 0.0)

def analytic(n: U32, x: U32, y: U32, z: U32, t: F32, axis: U32, hand: F32) -> Grid.Cell:
  match axis:
    case 3:
      oblique(n, x, y, z, t)
    case _:
      Sim.plane(n, x, y, z, t, axis, hand)

def reference_error(tree: Grid.Tree, +n: U32, +offset: U32, +t: F32, +axis: U32, +hand: F32) -> Error:
  match tree:
    case Grid.Leaf{cell}:
      error(cell, analytic(n, (offset % n : U32), (offset / n % n : U32), (offset / (n * n) : U32), t, axis, hand))
    case Grid.Fork{half, left, right}:
      combine_error(reference_error(left, n, offset, t, axis, hand),
        reference_error(right, n, (offset + half : U32), t, axis, hand))

def wave_error(world: Sim.World, axis: U32, hand: F32) -> Error:
  match world:
    case Sim.World{Grid.Grid{+n, tree}, steps}:
      reference_error(tree, n, 0, (U32.to_f32(steps) * 0.4 / U32.to_f32(n) : F32), axis, hand)

def rms(result: Error, n: U32) -> F32:
  match result:
    case Error{sum, _}:
      F32.sqrt((sum / (6.0 * U32.to_f32(n)) : F32))

def maximum(result: Error) -> F32:
  match result:
    case Error{_, value}:
      value

def wave_checks() -> IO(Unit):
  +coarse = wave_error(Sim.evolve(20n, Sim.World{Sim.make(~Sim.wave_x, 3n), 0}), 0, 1.0)
  +fine = wave_error(Sim.evolve(40n, Sim.World{Sim.make(~Sim.wave_x, 4n), 0}), 0, 1.0)
  +y = wave_error(Sim.evolve(20n, Sim.World{Sim.make(~Sim.wave_y, 3n), 0}), 1, (0.0 - 1.0 : F32))
  +z = wave_error(Sim.evolve(20n, Sim.World{Sim.make(~Sim.wave_z, 3n), 0}), 2, 1.0)
  +a = rms(coarse, 512)
  +b = rms(fine, 4096)
  +ma = maximum(coarse)
  +mb = maximum(fine)
  do IO<Unit>:
    IO.print("wave t=1 RMS: 8^3=" ++ F32.show(a) ++ " 16^3=" ++ F32.show(b))
    IO.print("wave t=1 Linf: 8^3=" ++ F32.show(ma) ++ " 16^3=" ++ F32.show(mb))
    expect((a < 0.02 : F32) && (b < 0.005 : F32), "analytic wave travels at c=1, not an arbitrary animation rate")
    expect((a / b > 3.5 : F32) && (a / b < 4.5 : F32) &&
      (ma / mb > 3.5 : F32) && (ma / mb < 4.5 : F32), "second-order space/time refinement at fixed Courant ratio")
    expect(near(a, rms(y, 512), 0.000001) && near(a, rms(z, 512), 0.000001), "all three propagation axes and both polarizations agree")

def oblique_checks() -> IO(Unit):
  +coarse = wave_error(Sim.evolve(7n, Sim.World{Sim.make(~oblique_seed, 3n), 0}), 3, 1.0)
  +fine = wave_error(Sim.evolve(14n, Sim.World{Sim.make(~oblique_seed, 4n), 0}), 3, 1.0)
  +a = rms(coarse, 512)
  +b = rms(fine, 4096)
  do IO<Unit>:
    IO.print("oblique wave t=0.35 RMS: 8^3=" ++ F32.show(a) ++ " 16^3=" ++ F32.show(b))
    expect((a < 0.01 : F32) && (b < 0.0025 : F32) &&
      (a / b > 3.5 : F32) && (a / b < 4.5 : F32), "oblique 3D wave refines at a noninteger period")

type Drift is Data:
  Drift{energy: F32, invariant: F32, divergence: F32, valid: Bool}

def observe(stats: Diag.Stats, +e0: F32, +h0: F32, previous: Drift) -> Drift:
  match stats previous:
    case Diag.Stats{e, h, de, db, peak, finite} Drift{a, b, d, ok}:
      Drift{Math.max(a, F32.abs((e / e0 - 1.0 : F32))),
        Math.max(b, F32.abs((h / h0 - 1.0 : F32))),
        Math.max(d, Math.max(de, db)), ok && finite && (peak < 1.0 : F32)}

# Measure EVERY step, not just an endpoint that might hide energy oscillation.
def history(fuel: Nat, +world: Sim.World, +e0: F32, +h0: F32, drift: Drift) -> Drift:
  match fuel:
    case 0n:
      drift
    case 1n+remaining:
      +next = Sim.step(world)
      history(remaining, next, e0, h0, observe(Diag.measure(grid_of(next)), e0, h0, drift))

def conservation_report(drift: Drift, +energy_budget: F32) -> IO(Unit):
  match drift:
    case Drift{+energy, +invariant, +divergence, valid}:
      do IO<Unit>:
        IO.print("pulse 100 steps max relative energy drift=" ++ F32.show(energy) ++
          " invariant drift=" ++ F32.show(invariant) ++ " max divergence=" ++ F32.show(divergence))
        IO.print("zero-rotation initial-state energy-oscillation bound=" ++ F32.show(energy_budget))
        expect(valid, "localized pulse remains finite with positive diagnostic capacity")
        expect((energy <= energy_budget + 0.00002 : F32), "ordinary energy obeys its initial-state KDK oscillation bound")
        expect((invariant < 0.00002 : F32), "modified KDK invariant stays within F32 tolerance")
        expect((divergence < 0.00005 : F32), "localized 3D pulse preserves both zero-divergence constraints")

def conservation_start(grid: Grid.Grid, stats: Diag.Stats) -> IO(Unit):
  match stats:
    case Diag.Stats{+e, +h, _, _, _, _}:
      # For b(0)=0, each stable Fourier oscillator has H_k <= E_k(t) <= E_k(0).
      # Thus |E(t)/E(0)-1| <= 1-H(0)/E(0), not an arbitrary drift percentage.
      conservation_report(history(100n, Sim.World{grid, 0}, e, h, Drift{0.0, 0.0, 0.0, True{}}),
        (1.0 - h / e : F32))

def conservation_checks() -> IO(Unit):
  +grid = Sim.make(~Sim.pulse, 3n)
  conservation_start(grid, Diag.measure(grid))

def absent(matrix: Maybe<Matrix4.Matrix4<F32>>) -> Bool:
  match matrix:
    case None{}:
      True{}
    case Some{_}:
      False{}

def tensor_fixture(matrix: Maybe<Matrix4.Matrix4<F32>>) -> Bool:
  match matrix:
    case Some{Matrix4.Matrix4{Matrix4.Row4{tt, tx, ty, tz}, Matrix4.Row4{xt, +xx, xy, xz},
        Matrix4.Row4{yt, yx, yy, yz}, Matrix4.Row4{zt, zx, zy, zz}}}:
      near(tt, (0.0 - 0.671875 : F32), 0.000001) &&
      near(tx, (0.0 - 0.25 : F32), 0.000001) && near(ty, 0.125, 0.000001) && near(tz, (0.0 - 0.5 : F32), 0.000001) &&
      near(xt, 0.25, 0.000001) && near(yt, (0.0 - 0.125 : F32), 0.000001) && near(zt, 0.5, 0.000001) &&
      near(xx, (64.0 / 43.0 : F32), 0.000001) && near(yy, xx, 0.0) && near(zz, xx, 0.0) &&
      near(xy, (0.0 - 0.3 : F32), 0.000001) && near(yx, 0.3, 0.000001) &&
      near(xz, 0.2, 0.000001) && near(zx, (0.0 - 0.2 : F32), 0.000001) &&
      near(yz, (0.0 - 0.1 : F32), 0.000001) && near(zy, 0.1, 0.000001)
    case None{}:
      False{}

def diagnostic_checks() -> IO(Unit):
  +cell = {Grid.Cell{Tensor.Vector3{0.25, (0.0 - 0.125 : F32), 0.5}, Tensor.Vector3{0.1, 0.2, 0.3}} : Grid.Cell}
  do IO<Unit>:
    expect(near(Diag.load(cell), 0.328125, 0.0), "transverse pressure fraction is |v_perp/c|^2")
    expect(tensor_fixture(Diag.tensor(cell)), "all 16 spacetime tensor components preserve the shared layout")
    expect(absent(Diag.tensor(Grid.Cell{Tensor.Vector3{1.0, 0.0, 0.0}, V.zero()})), "zero capacity gives no finite tensor, not a fake cavity")
    expect(absent(Diag.tensor(Grid.Cell{Tensor.Vector3{2.0, 0.0, 0.0}, V.zero()})), "negative capacity is not clamped")
    expect(absent(Diag.tensor(Grid.Cell{V.zero(), Tensor.Vector3{(0.0 / 0.0 : F32), 0.0, 0.0}})), "nonfinite rotation rejects tensor reconstruction")

def main() -> IO(Unit):
  do IO<Unit>:
    topology_checks()
    operator_checks()
    orientation_checks()
    custom_step_checks()
    wave_checks()
    oblique_checks()
    conservation_checks()
    diagnostic_checks()
