import Base
import ./FloatTensor.bend as Tensor
import ./Math.bend as Math

# Camera + material transforms, built once per frame, not once per ray sample.
type Scene is Data:
  Scene{
    spin_cos: F32, spin_sin: F32,
    drift_cos: F32, drift_sin: F32,
    compression: F32, yaw_cos: F32, yaw_sin: F32,
    cutaway: Bool
  }

type Sample is Data:
  Sample{density: F32, heat: F32}

type Rates is Data:
  Rates{compression: F32, spin: F32, drift: F32}

def density(sample: Sample) -> F32:
  match sample:
    case Sample{value, _}:
      value

def heat(sample: Sample) -> F32:
  match sample:
    case Sample{_, value}:
      value

def from_probes(radial: Tensor.Vector3, temporal: Tensor.Vector3) -> Rates:
  match radial temporal:
    case Tensor.Vector3{radial_scale, spin, _} Tensor.Vector3{_, _, drift}:
      Rates{(1.0 + 0.35 * (radial_scale - 1.0) : F32), spin, drift}

# Actual probes of the shared RCCM matrix, in a local toroidal frame:
# x = tube radial direction; y = tube vertical direction; z = ring tangent.
# The spatial block gives rotation; the time-space term gives tangential drift.
# Mapping these rates onto a torus and maintaining a dye source is OUR toy closure.
def rates(admittance: F32, coupling: F32) -> Rates:
  +matrix = Tensor.matrix(admittance, coupling, 1.0, 1.0,
    Tensor.Vector3{0.0, 0.0, 0.45}, Tensor.Vector3{0.0, 0.0, 1.2})
  from_probes(
    Tensor.apply_spatial(matrix, 0.0, Tensor.Vector3{1.0, 0.0, 0.0}),
    Tensor.apply_spatial(matrix, 1.0, Tensor.Vector3{0.0, 0.0, 0.0}))

def from_rates(+spin_phase: F32, +drift_phase: F32, +yaw: F32, cutaway: Bool, rates: Rates) -> Scene:
  match rates:
    case Rates{compression, _, _}:
      Scene{F32.cos(spin_phase), F32.sin(spin_phase),
        F32.cos(drift_phase), F32.sin(drift_phase),
        compression, F32.cos(yaw), F32.sin(yaw), cutaway}

# Interactive state stores accumulated phases so rate edits do not teleport dye.
def from_phases(spin_phase: F32, drift_phase: F32, yaw: F32, admittance: F32, coupling: F32, cutaway: Bool) -> Scene:
  from_rates(spin_phase, drift_phase, yaw, cutaway, rates(admittance, coupling))

# Deterministic fixed-rate entry for snapshots/benchmarks.
def at_time(+time: F32, yaw: F32, cutaway: Bool, +rates: Rates) -> Scene:
  match rates:
    case Rates{_, spin, drift}:
      from_rates((spin * time : F32), (drift * time : F32), yaw, cutaway, rates)

def scene(time: F32, yaw: F32, admittance: F32, coupling: F32, cutaway: Bool) -> Scene:
  at_time(time, yaw, cutaway, rates(admittance, coupling))

def material(
  +radial: F32, +height: F32, +azimuth_x: F32, +azimuth_z: F32,
  spin_cos: F32, spin_sin: F32, drift_cos: F32, drift_sin: F32
) -> Sample:
  +sc = spin_cos
  +ss = spin_sin
  +dc = drift_cos
  +ds = drift_sin
  +rest_radial = (radial * sc + height * ss : F32)
  +rest_height = (height * sc - radial * ss : F32)
  +rest_x = ((azimuth_x * dc + azimuth_z * ds) * (1.16 + rest_radial) : F32)
  +rest_z = ((azimuth_z * dc - azimuth_x * ds) * (1.16 + rest_radial) : F32)
  +warp = F32.sin((3.1 * rest_x + 4.7 * rest_height - 2.3 * rest_z : F32))
  +broad = F32.sin((8.0 * rest_x + 6.0 * rest_height + 4.0 * rest_z + warp : F32))
  +cross = F32.sin((0.0 - 5.0 * rest_x + 11.0 * rest_height + 7.0 * rest_z : F32))
  +fine = F32.sin((22.0 * rest_x - 17.0 * rest_height + 19.0 * rest_z + 2.0 * warp : F32))
  +noise = Math.clamp((0.5 + 0.3 * broad * cross + 0.2 * fine : F32), 0.0, 1.0)
  +envelope = Math.max(0.0, (1.0 - (radial * radial + height * height) / 0.29 : F32))
  +filament = Math.clamp(((noise - 0.43) * 3.0 : F32), 0.0, 1.0)
  +density = (envelope * envelope * (0.015 + 9.0 * filament * filament * filament) : F32)
  Sample{density, Math.clamp((0.5 + 1.2 * F32.sin((2.0 * rest_x - 3.0 * rest_z + 4.0 * rest_height : F32)) : F32), 0.0, 1.0)}

def inside(active: Bool, radial: F32, height: F32, azimuth_x: F32, azimuth_z: F32, scene: Scene) -> Sample:
  match active:
    case False{}:
      Sample{0.0, 0.0}
    case True{}:
      Scene{spin_cos, spin_sin, drift_cos, drift_sin, _, _, _, _} = scene
      material(radial, height, azimuth_x, azimuth_z, spin_cos, spin_sin, drift_cos, drift_sin)

def sample(+scene: Scene, +x: F32, +y: F32, +z: F32) -> Sample:
  Scene{_, _, _, _, +compression, _, _, cutaway} = scene
  +radius = F32.sqrt((x * x + z * z + 0.000001 : F32))
  +radial = ((radius - 1.16) * compression : F32)
  +height = (y * compression : F32)
  active = ((radial * radial + height * height < 0.29 : F32)
    && Bool.not(cutaway && (x > 0.0 : F32)))
  inside(active, radial, height, (x / radius : F32), (z / radius : F32), scene)
