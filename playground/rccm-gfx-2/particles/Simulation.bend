import Base
import ../vortex/FloatTensor.bend as Tensor
import ../vortex/Math.bend as Math
import ./Vector.bend as Vector

# Persistent, interacting particles, not samples of an analytic flow field.
# All constants below are dimensionless toy choices, NOT RCCM field equations.
type Body is Data:
  Body{id: U32, spin: F32, position: Tensor.Vector3, velocity: Tensor.Vector3,
    history: List<&2, Tensor.Vector3>}

type Particles is Data:
  One{body: Body}
  Two{left: Particles, right: Particles}

type World is Data:
  World{particles: Particles, steps: U32}

# A lean immutable interaction snapshot: no velocities or trails in the pair loop.
type Sample is Data:
  Sample{position: Tensor.Vector3, spin: F32}

# Spatial diagonal and three skew coefficients, obtained by probing the actual
# shared RCCM matrix. This is a cached linear map, not a second matrix layout.
# v_perp=0, c=t_p=1, Omega=(0.25,0.35,1); the time-space sector is unused.
type Response is Data:
  Response{diagonal: F32, wx: F32, wy: F32, wz: F32}

def coefficients(x_basis: Tensor.Vector3, y_basis: Tensor.Vector3) -> Response:
  match x_basis y_basis:
    case Tensor.Vector3{diagonal, wz, minus_wy} Tensor.Vector3{_, _, wx}:
      Response{diagonal, wx, (0.0 - minus_wy : F32), wz}

def response(admittance: F32, coupling: F32) -> Response:
  +matrix = Tensor.matrix(admittance, coupling, 1.0, 1.0,
    Vector.zero(), Tensor.Vector3{0.25, 0.35, 1.0})
  coefficients(
    Tensor.apply_spatial(matrix, 0.0, Tensor.Vector3{1.0, 0.0, 0.0}),
    Tensor.apply_spatial(matrix, 0.0, Tensor.Vector3{0.0, 1.0, 0.0}))

def symmetric(response: Response, displacement: Tensor.Vector3) -> Tensor.Vector3:
  match response:
    case Response{diagonal, _, _, _}:
      Vector.scale(diagonal, displacement)

def skew(response: Response, displacement: Tensor.Vector3) -> Tensor.Vector3:
  match response displacement:
    case Response{_, +wx, +wy, +wz} Tensor.Vector3{+x, +y, +z}:
      Tensor.Vector3{(wy * z - wz * y : F32), (wz * x - wx * z : F32),
        (wx * y - wy * x : F32)}

# r points FROM i TO j. q=(spin_i+spin_j)/2 is symmetric under pair exchange.
# F_ij = (12/256) w(d) [h(d,q) S r + 1.8 q A r].
# w=max(0,1-d/1.65)^2; h=0.22+0.78|q|-0.12/(d^2+0.0081).
# Soft-core repulsion, finite-range cohesion, and handed drive are invented.
# Exchange i,j negates both channels. No self force or division by distance.
def pair_force(+response: Response, self: Sample, other: Sample) -> Tensor.Vector3:
  match self other:
    case Sample{position, spin} Sample{other_position, other_spin}:
      +r = Vector.sub(other_position, position)
      +distance_squared = Vector.length_squared(r)
      +q = ((spin + other_spin) * 0.5 : F32)
      +falloff = Math.max(0.0, (1.0 - F32.sqrt(distance_squared) / 1.65 : F32))
      radial = (0.22 + 0.78 * F32.abs(q) - 0.12 / (distance_squared + 0.0081) : F32)
      Vector.scale((0.046875 * falloff * falloff : F32),
        Vector.add(Vector.scale(radial, symmetric(response, r)),
          Vector.scale((1.8 * q : F32), skew(response, r))))

def samples(particles: Particles, acc: List<&2, Sample>) -> List<&2, Sample>:
  match particles:
    case One{Body{_, spin, position, _, _}}:
      Sample{position, spin} <> acc
    case Two{left, right}:
      samples(left, samples(right, acc))

def force(peers: List<&2, Sample>, +response: Response, +self: Sample,
  acc: Tensor.Vector3) -> Tensor.Vector3:
  match peers:
    case []:
      acc
    case peer <> remaining:
      force(remaining, response, self, Vector.add(acc, pair_force(response, self, peer)))

def take_history(fuel: Nat, history: List<&2, Tensor.Vector3>) -> List<&2, Tensor.Vector3>:
  match fuel history:
    case 0n _:
      []
    case _ Nil{}:
      []
    case 1n+remaining Con{point, rest}:
      point <> take_history(remaining, rest)

def record(sample: Bool, position: Tensor.Vector3,
  history: List<&2, Tensor.Vector3>) -> List<&2, Tensor.Vector3>:
  match sample:
    case False{}:
      history
    case True{}:
      position <> take_history(13n, history)

# Semi-implicit Euler, fixed dt=1/120. The centered trap, damping and speed cap
# stabilize this driven toy; they deliberately do not conserve energy/momentum.
def integrate(+response: Response, peers: List<&2, Sample>, sample: Bool,
  body: Body) -> Body:
  match body:
    case Body{id, +spin, +position, velocity, history}:
      pair = force(peers, response, Sample{position, spin}, Vector.zero())
      trap = Vector.scale((0.35 + 0.24 * Vector.length_squared(position) : F32), position)
      +next_velocity = Vector.limit(Vector.scale(0.9933555,
        Vector.add(velocity, Vector.scale(0.008333333, Vector.sub(pair, trap)))), 2.8)
      Body{id, spin, Vector.add(position, Vector.scale(0.008333333, next_velocity)),
        next_velocity, record(sample, position, history)}

def step_tree(particles: Particles, +response: Response, +peers: List<&2, Sample>,
  +sample: Bool) -> Particles:
  match particles:
    case One{body}:
      One{integrate(response, peers, sample, body)}
    case Two{left, right}:
      a b = step_tree(left, response, peers, sample) step_tree(right, response, peers, sample)
      Two{a, b}

def step(world: World, response: Response) -> World:
  match world:
    case World{+particles, +steps}:
      World{step_tree(particles, response, samples(particles, []),
        U32.is_eq((steps % 6 : U32), 0)), (steps + 1 : U32)}

def evolve(fuel: Nat, world: World, +response: Response) -> World:
  match fuel:
    case 0n:
      world
    case 1n+remaining:
      evolve(remaining, step(world, response), response)

def seed_body(+id: U32, +seed: U32) -> Body:
  +spin = Math.pick((id < 128 : U32), 1.0, (0.0 - 1.0 : F32))
  +index = U32.to_f32((id % 128 : U32))
  +height = (1.0 - 2.0 * (index + 0.5) / 128.0 : F32)
  +radius = F32.sqrt((1.0 - height * height : F32))
  +angle = (index * 2.3999632 + spin * 0.4 : F32)
  +x = (radius * F32.cos(angle) : F32)
  +y = (radius * F32.sin(angle) : F32)
  +z = height
  # Seeds change only initial conditions, never the interaction law.
  +collision = U32.is_eq(seed, 1)
  +shell = U32.is_eq(seed, 2)
  +position = {Tensor.Vector3{
    Math.pick(shell, (1.0 * x : F32),
      (spin * Math.pick(collision, 0.95, 0.55) + 0.42 * x : F32)),
    Math.pick(shell, (1.0 * y : F32), (0.5 * y : F32)),
    Math.pick(shell, (0.65 * z : F32), (0.5 * z : F32))} : Tensor.Vector3}
  velocity = {Tensor.Vector3{
    Math.pick(collision, (0.0 - spin * 0.8 : F32), (0.0 - spin * y * 0.45 : F32)),
    Math.pick(collision, 0.0, (spin * x * 0.45 : F32)),
    (spin * 0.12 * y : F32)} : Tensor.Vector3}
  Body{id, spin, position, velocity, []}

def seed_tree(+depth: Nat, +offset: U32, seed: U32) -> Particles:
  match depth:
    case 0n:
      One{seed_body(offset, seed)}
    case 1n+remaining:
      +seed = seed
      Two{seed_tree(remaining, offset, seed),
        seed_tree(remaining, (offset + (1 << remaining : U32) : U32), seed)}

def initial(seed: U32) -> World:
  World{seed_tree(8n, 0, seed), 0}

def burst_tree(particles: Particles) -> Particles:
  match particles:
    case One{Body{id, spin, +position, velocity, history}}:
      One{Body{id, spin, position, Vector.limit(Vector.add(velocity,
        Vector.scale((0.9 / Math.max(0.2, F32.sqrt(Vector.length_squared(position))) : F32), position)), 2.8),
        history}}
    case Two{left, right}:
      Two{burst_tree(left), burst_tree(right)}

def burst(world: World) -> World:
  match world:
    case World{particles, steps}:
      World{burst_tree(particles), steps}
