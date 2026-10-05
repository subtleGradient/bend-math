import Base
import ./FloatTensor.bend as Tensor
import ./Controls.bend as Controls
import ./Field.bend as Field

# Runtime regressions for opaque F32 arithmetic; deliberately NOT proof claims.
def expect(ok: Bool, +label: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("PASS " ++ label)
    case False{}:
      IO.die(Unit, 1, "FAIL " ++ label)

def same_vector(left: Tensor.Vector3, right: Tensor.Vector3) -> Bool:
  match left right:
    case Tensor.Vector3{x, y, z} Tensor.Vector3{a, b, c}:
      F32.is_eq(x, a) && F32.is_eq(y, b) && F32.is_eq(z, c)

def probe(coupling: F32) -> Tensor.Vector3:
  Tensor.apply_spatial(
    Tensor.matrix(0.5, coupling, 1.0, 1.0,
      Tensor.Vector3{0.0, 0.0, 0.5}, Tensor.Vector3{0.0, 0.0, 2.0}),
    1.0, Tensor.Vector3{1.0, 0.0, 0.0})

def same_scene(left: Field.Scene, right: Field.Scene) -> Bool:
  match left right:
    case Field.Scene{a, b, c, d, e, f, g, h} Field.Scene{i, j, k, l, m, n, o, p}:
      F32.is_eq(a, i) && F32.is_eq(b, j) && F32.is_eq(c, k) &&
        F32.is_eq(d, l) && F32.is_eq(e, m) && F32.is_eq(f, n) &&
        F32.is_eq(g, o) && Bool.not(Bool.xor(h, p))

def still_paused(view: Controls.View) -> Bool:
  match view:
    case Controls.View{spin, drift, yaw, _, _, paused, _, _}:
      F32.is_eq(spin, 1.0) && F32.is_eq(drift, 0.5) && F32.is_eq(yaw, 2.0) && paused

def admittance_is(view: Maybe<Controls.View>, expected: F32) -> Bool:
  match view:
    case Some{Controls.View{_, _, _, value, _, _, _, _}}:
      F32.is_eq(value, expected)
    case None{}:
      False{}

def scene_for(view: Controls.View) -> Field.Scene:
  match view:
    case Controls.View{spin, drift, yaw, admittance, coupling, _, _, cutaway}:
      Field.from_phases(spin, drift, yaw, admittance, coupling, cutaway)

def preserves_phase(changed: Maybe<Controls.View>, before: Field.Scene) -> Bool:
  match changed:
    case Some{view}:
      same_scene(scene_for(view), before)
    case None{}:
      False{}

def remains_stopped(changed: Maybe<Controls.View>, before: Field.Scene) -> Bool:
  match changed:
    case Some{view}:
      same_scene(scene_for(Controls.advance(0.1, view)), before)
    case None{}:
      False{}

def phase_fixture() -> Controls.View:
  Controls.View{12.0, 4.5, 0.35, 0.82, 1.0, False{}, False{}, False{}}

def main() -> IO(Unit):
  do IO<Unit>:
    expect(same_vector(probe(1.0), Tensor.Vector3{4.0, 2.0, 0.5}), "tensor affects spatial motion")
    expect(same_vector(probe(0.0), Tensor.Vector3{4.0, 0.0, 0.0}), "symmetric-only removes spin and drift")
    expect(same_vector(probe((0.0 - 1.0 : F32)), Tensor.Vector3{4.0, (0.0 - 2.0 : F32), (0.0 - 0.5 : F32)}), "negative coupling reverses spin and drift")
    expect(same_scene(Field.scene(2.0, 0.35, 0.82, 0.0, False{}), Field.scene(4.0, 0.35, 0.82, 0.0, False{})), "zero coupling freezes dye at fixed camera")
    expect(Bool.not(same_scene(Field.scene(2.0, 0.35, 0.82, 1.0, False{}), Field.scene(4.0, 0.35, 0.82, 1.0, False{}))), "nonzero coupling animates dye")
    expect(still_paused(Controls.advance(0.125, Controls.View{1.0, 0.5, 2.0, 0.82, 1.0, True{}, True{}, False{}})), "pause freezes phases and camera")
    expect(admittance_is(Controls.key(97, Controls.View{1.0, 0.5, 2.0, 0.55, 1.0, False{}, True{}, False{}}), 0.55), "admittance lower clamp")
    expect(admittance_is(Controls.key(100, Controls.View{1.0, 0.5, 2.0, 1.0, 1.0, False{}, True{}, False{}}), 1.0), "admittance upper clamp")
    expect(preserves_phase(Controls.key(101, phase_fixture()), scene_for(phase_fixture())), "twist edit preserves current orientation")
    expect(preserves_phase(Controls.key(51, phase_fixture()), scene_for(phase_fixture())), "reversal preserves current orientation")
    expect(remains_stopped(Controls.key(49, phase_fixture()), scene_for(phase_fixture())), "symmetric-only stops in place")
