import Base
import ../vortex/FloatTensor.bend as Tensor
import ../vortex/Math.bend as Math
import ./Vector.bend as Vector
import ./Simulation.bend as Simulation
import ./Controls.bend as Controls
import ./Render.bend as Render
import ./Hud.bend as Hud

# Runtime F32 regressions, not rfl proofs or claims of physical validity.
def expect(ok: Bool, +label: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("PASS " ++ label)
    case False{}:
      IO.die(Unit, 1, "FAIL " ++ label)

def near(left: F32, right: F32) -> Bool:
  (F32.abs((left - right : F32)) < 0.00001 : F32)

def near_vector(left: Tensor.Vector3, right: Tensor.Vector3) -> Bool:
  match left right:
    case Tensor.Vector3{x, y, z} Tensor.Vector3{a, b, c}:
      near(x, a) && near(y, b) && near(z, c)

def same_vector(left: Tensor.Vector3, right: Tensor.Vector3) -> Bool:
  match left right:
    case Tensor.Vector3{x, y, z} Tensor.Vector3{a, b, c}:
      U32.is_eq(F32.bits(x), F32.bits(a)) && U32.is_eq(F32.bits(y), F32.bits(b)) &&
        U32.is_eq(F32.bits(z), F32.bits(c))

def same_history(left: List<&2, Tensor.Vector3>, right: List<&2, Tensor.Vector3>) -> Bool:
  match left right:
    case Nil{} Nil{}:
      True{}
    case Con{x, xs} Con{y, ys}:
      same_vector(x, y) && same_history(xs, ys)
    case _ _:
      False{}

def same_body(left: Simulation.Body, right: Simulation.Body) -> Bool:
  match left right:
    case Simulation.Body{id, spin, p, v, h} Simulation.Body{other_id, other_spin, a, b, c}:
      U32.is_eq(id, other_id) && F32.is_eq(spin, other_spin) &&
        same_vector(p, a) && same_vector(v, b) && same_history(h, c)

def same_particles(left: Simulation.Particles, right: Simulation.Particles) -> Bool:
  match left right:
    case Simulation.One{x} Simulation.One{y}:
      same_body(x, y)
    case Simulation.Two{a, b} Simulation.Two{c, d}:
      same_particles(a, c) && same_particles(b, d)
    case _ _:
      False{}

def same_world(left: Simulation.World, right: Simulation.World) -> Bool:
  match left right:
    case Simulation.World{a, steps} Simulation.World{b, other_steps}:
      U32.is_eq(steps, other_steps) && same_particles(a, b)

def world_of(scene: Controls.Scene) -> Simulation.World:
  match scene:
    case Controls.Scene{world, _, _, _, _, _, _, _, _}:
      world

def count(particles: Simulation.Particles) -> U32:
  match particles:
    case Simulation.One{_}:
      1
    case Simulation.Two{left, right}:
      (count(left) + count(right) : U32)

def history_length(history: List<&2, Tensor.Vector3>) -> U32:
  match history:
    case []:
      0
    case _ <> rest:
      (1 + history_length(rest) : U32)

def bounded_vector(vector: Tensor.Vector3) -> Bool:
  match vector:
    case Tensor.Vector3{x, y, z}:
      (F32.abs(x) < 1000.0 : F32) && (F32.abs(y) < 1000.0 : F32) &&
        (F32.abs(z) < 1000.0 : F32)

def stable_particles(particles: Simulation.Particles) -> Bool:
  match particles:
    case Simulation.One{Simulation.Body{_, _, +position, +velocity, history}}:
      bounded_vector(position) && bounded_vector(velocity) &&
        (Vector.length_squared(position) < 16.0 : F32) &&
        (Vector.length_squared(velocity) <= 7.8401 : F32) &&
        (history_length(history) <= 14 : U32)
    case Simulation.Two{left, right}:
      stable_particles(left) && stable_particles(right)

def stable(world: Simulation.World) -> Bool:
  match world:
    case Simulation.World{+particles, _}:
      U32.is_eq(count(particles), 256) && stable_particles(particles)

def population_kept(world: Simulation.World) -> Bool:
  match world:
    case Simulation.World{particles, _}:
      U32.is_eq(count(particles), 256)

def steps_are(world: Simulation.World, expected: U32) -> Bool:
  match world:
    case Simulation.World{_, steps}:
      U32.is_eq(steps, expected)

def coefficient_is(scene: Controls.Scene, expected_admittance: F32, expected_coupling: F32) -> Bool:
  match scene:
    case Controls.Scene{_, admittance, coupling, _, _, _, _, _, _}:
      near(admittance, expected_admittance) && near(coupling, expected_coupling)

def paused_is_still(scene: Controls.Scene, before: Controls.Scene) -> Bool:
  match scene before:
    case Controls.Scene{world, _, _, paused, _, _, _, yaw, _} Controls.Scene{old_world, _, _, _, _, _, _, old_yaw, _}:
      paused && F32.is_eq(yaw, old_yaw) && same_world(world, old_world)

def scene_matches(next: Maybe<Controls.Scene>, +before: Simulation.World) -> Bool:
  match next:
    case Some{scene}:
      same_world(world_of(scene), before)
    case None{}:
      False{}

def first_frame_is_still(next: Maybe<Controls.State>) -> Bool:
  match next:
    case Some{Controls.State{scene, _, _, _, _, _}}:
      steps_are(world_of(scene), 0)
    case None{}:
      False{}

def quit(next: Maybe<Controls.Scene>) -> Bool:
  match next:
    case None{}:
      True{}
    case Some{_}:
      False{}

def y_position(body: Simulation.Body) -> F32:
  match body:
    case Simulation.Body{_, _, Tensor.Vector3{_, y, _}, _, _}:
      y

def displaced_body(response: Simulation.Response) -> Simulation.Body:
  Simulation.integrate(response, [Simulation.Sample{Tensor.Vector3{0.6, 0.0, 0.0}, 1.0}],
    False{}, Simulation.Body{0, 1.0, Vector.zero(), Vector.zero(), []})

def flags(next: Maybe<Controls.Input>, expected_paused: Bool, expected_orbit: Bool,
  expected_trails: Bool) -> Bool:
  match next:
    case Some{Controls.Input{Controls.Scene{_, _, _, paused, orbit, trails, _, _, _}, _, _}}:
      Bool.not(Bool.xor(paused, expected_paused)) && Bool.not(Bool.xor(orbit, expected_orbit)) &&
        Bool.not(Bool.xor(trails, expected_trails))
    case None{}:
      False{}

def input_coefficient(next: Maybe<Controls.Input>, admittance: F32, coupling: F32) -> Bool:
  match next:
    case Some{Controls.Input{scene, _, _}}:
      coefficient_is(scene, admittance, coupling)
    case None{}:
      False{}

def reset_frame_is_initial(next: Maybe<Controls.State>) -> Bool:
  match next:
    case Some{Controls.State{scene, _, _, _, _, _}}:
      same_world(world_of(scene), Simulation.initial(0))
    case None{}:
      False{}

def exchange(+response: Simulation.Response, +left: Simulation.Sample, +right: Simulation.Sample) -> Bool:
  near_vector(Simulation.pair_force(response, left, right),
    Vector.scale((0.0 - 1.0 : F32), Simulation.pair_force(response, right, left)))

def main() -> IO(Unit):
  do IO<Unit>:
    +r : Tensor.Vector3 = Tensor.Vector3{0.4, (0.0 - 0.7 : F32), 0.2}
    +positive : Simulation.Response = Simulation.response(0.8, 1.0)
    +negative : Simulation.Response = Simulation.response(0.8, (0.0 - 1.0 : F32))
    +radial : Simulation.Response = Simulation.response(0.8, 0.0)
    +origin : Simulation.Sample = Simulation.Sample{Vector.zero(), 1.0}
    +other : Simulation.Sample = Simulation.Sample{r, 1.0}
    +fixture : Controls.Scene = Controls.advance(0.05, Controls.initial_scene())
    expect(near_vector(Vector.add(Simulation.symmetric(positive, r), Simulation.skew(positive, r)),
      Tensor.apply_spatial(Tensor.matrix(0.8, 1.0, 1.0, 1.0, Vector.zero(),
        Tensor.Vector3{0.25, 0.35, 1.0}), 0.0, r)), "cached response equals actual matrix multiplication")
    expect(near_vector(Simulation.skew(positive, Tensor.Vector3{1.0, 0.0, 0.0}),
      Tensor.Vector3{0.0, 1.0, (0.0 - 0.35 : F32)}), "matrix cross-product sign convention")
    expect(near_vector(Simulation.symmetric(radial, r), Vector.scale(1.5625, r)), "admittance enters spatial symmetric sector")
    expect(near(Vector.dot(r, Simulation.skew(positive, r)), 0.0), "skew response is perpendicular to displacement")
    expect(near_vector(Simulation.skew(radial, r), Vector.zero()), "zero coupling removes skew response")
    expect(near_vector(Simulation.skew(negative, r), Vector.scale((0.0 - 1.0 : F32), Simulation.skew(positive, r))), "reversed coupling negates skew response")
    expect(near_vector(Simulation.symmetric(positive, r), Simulation.symmetric(negative, r)), "reversal leaves symmetric sector unchanged")
    expect(exchange(positive, origin, other), "same-population pair exchange is equal and opposite")
    expect(exchange(positive, origin, Simulation.Sample{r, (0.0 - 1.0 : F32)}), "mixed-population pair exchange is equal and opposite")
    expect(near_vector(Simulation.pair_force(positive, origin, Simulation.Sample{r, (0.0 - 1.0 : F32)}),
      Simulation.pair_force(radial, origin, Simulation.Sample{r, (0.0 - 1.0 : F32)})), "opposite handedness cancels pair skew channel")
    expect(near_vector(Simulation.pair_force(positive, origin, origin), Vector.zero()), "coincident particles have finite zero pair response")
    expect(near_vector(Simulation.pair_force(positive, origin, Simulation.Sample{Tensor.Vector3{2.0, 0.0, 0.0}, 1.0}), Vector.zero()), "interaction vanishes beyond cutoff")
    expect((Vector.dot(Tensor.Vector3{0.05, 0.0, 0.0},
      Simulation.pair_force(radial, origin, Simulation.Sample{Tensor.Vector3{0.05, 0.0, 0.0}, 1.0})) < 0.0 : F32), "soft core repels nearby particles")
    expect((Vector.dot(Tensor.Vector3{0.6, 0.0, 0.0},
      Simulation.pair_force(radial, origin, Simulation.Sample{Tensor.Vector3{0.6, 0.0, 0.0}, 1.0})) > 0.0 : F32), "same-population cohesion attracts beyond core")
    expect((y_position(displaced_body(positive)) > 0.0 : F32) &&
      (y_position(displaced_body(negative)) < 0.0 : F32) &&
      near(y_position(displaced_body(radial)), 0.0), "neighbor interactions change evolving trajectories with handedness")
    expect(same_world(world_of(Controls.key(51, fixture)), world_of(fixture)), "coupling reversal preserves world and trails")
    expect(same_world(world_of(Controls.key(97, fixture)), world_of(fixture)), "admittance edit preserves world and trails")
    expect(same_world(world_of(Controls.key(116, fixture)), world_of(fixture)), "trail visibility does not change physics")
    expect(paused_is_still(Controls.advance(0.05, Controls.key(32, Controls.key(111, fixture))),
      fixture), "pause freezes particles history and camera")
    expect(same_world(world_of(Controls.advance(0.05, Controls.initial_scene())),
      world_of(Controls.advance(0.025, Controls.advance(0.025, Controls.initial_scene())))), "fixed stepping is independent of frame partition")
    expect(steps_are(world_of(Controls.advance(10.0, Controls.initial_scene())), 6), "long frames have bounded catch-up")
    expect(first_frame_is_still(Controls.tick(10000n, [], Controls.initial())), "first frame does not integrate from epoch zero")
    expect(flags(Controls.events([Key{32, True{}}, Key{32, True{}}, Key{32, False{}}],
      Controls.Input{Controls.initial_scene(), [], False{}}), True{}, True{}, True{}), "holding space toggles once")
    expect(flags(Controls.events([Key{32, True{}}, Key{32, True{}}, Key{32, False{}}, Key{32, True{}}],
      Controls.Input{Controls.initial_scene(), [], False{}}), False{}, True{}, True{}), "space release permits a second press")
    expect(flags(Controls.events([Key{79, True{}}, Key{111, True{}}, Key{111, False{}}, Key{84, True{}}, Key{116, True{}}],
      Controls.Input{Controls.initial_scene(), [], False{}}), False{}, False{}, False{}), "orbit and trails are press-edge actions across uppercase aliases")
    expect(input_coefficient(Controls.events([Key{101, True{}}, Key{101, True{}}],
      Controls.Input{Controls.initial_scene(), [], False{}}), 0.82, 1.4), "coefficient keys retain auto-repeat")
    expect(reset_frame_is_initial(Controls.tick(1050n, [Key{114, True{}}],
      Controls.State{fixture, 1000n, 1000n, 1, 0, []})), "reset discards previous frame time budget")
    expect(coefficient_is(Controls.key(97, Controls.Scene{Simulation.initial(0), 0.55, 1.0,
      False{}, False{}, True{}, 0, 0.35, 0.0}), 0.55, 1.0), "admittance lower clamp")
    expect(coefficient_is(Controls.key(100, Controls.Scene{Simulation.initial(0), 1.0, 1.0,
      False{}, False{}, True{}, 0, 0.35, 0.0}), 1.0, 1.0), "admittance upper clamp")
    expect(coefficient_is(Controls.key(69, Controls.Scene{Simulation.initial(0), 0.82, 2.0,
      False{}, False{}, True{}, 0, 0.35, 0.0}), 0.82, 2.0), "uppercase control and coupling upper clamp")
    expect(coefficient_is(Controls.key(113, Controls.Scene{Simulation.initial(0), 0.82, (0.0 - 2.0 : F32),
      False{}, False{}, True{}, 0, 0.35, 0.0}), 0.82, (0.0 - 2.0 : F32)), "coupling lower clamp")
    expect(scene_matches(Controls.event(Key{114, True{}}, fixture), Simulation.initial(0)), "reset restores deterministic initial particles")
    expect(scene_matches(Controls.event(Key{53, True{}}, fixture), Simulation.initial(1)), "collision seed replaces initial conditions")
    expect(scene_matches(Controls.event(Key{54, True{}}, fixture), Simulation.initial(2)), "shell seed replaces initial conditions")
    expect(scene_matches(Controls.event(Key{114, False{}}, fixture), world_of(fixture)), "key release does not reset")
    expect(quit(Controls.event(Key{27, True{}}, fixture)) && quit(Controls.event(Close{}, fixture)), "escape and window close quit")
    expect(population_kept(Simulation.burst(world_of(fixture))) &&
      Bool.not(same_world(Simulation.burst(world_of(fixture)), world_of(fixture))), "burst changes velocities without adding particles")
    expect(U32.is_eq(Hud.color(Hud.Status{0.82, 1.0, False{}, False{}, True{}, 0, 0}, 256, 280), 0), "HUD leaves simulation viewport transparent")
    expect(near(Render.energy(Render.stroke(Render.Point{2.0, 2.0, 1.0}, Render.Point{2.0, 2.0, 1.0},
      4.0, 3.0, False{}), 2.0, 2.0), 3.0), "zero-length head has finite peak brightness")
    expect(stable(Simulation.evolve(1200n, Simulation.initial(0), Simulation.response(0.55, 2.0))), "10s minimum-admittance maximum-coupling stability")
    expect(stable(Simulation.evolve(1200n, Simulation.initial(1), Simulation.response(0.55, (0.0 - 2.0 : F32)))), "10s reversed collision stability")
    expect(stable(Simulation.evolve(1200n, Simulation.initial(2), Simulation.response(1.0, 0.0))), "10s symmetric shell stability")
