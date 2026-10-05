import Base
import ../vortex/Math.bend as Math
import ./Simulation.bend as Simulation

type Scene is Data:
  Scene{world: Simulation.World, admittance: F32, coupling: F32,
    paused: Bool, orbit: Bool, trails: Bool, seed: U32, yaw: F32, remainder: F32}

type State is Data:
  State{scene: Scene, last_frame: Nat, fps_epoch: Nat, frames: U32, fps: U32,
    held: List<&2, U32>}

# Transient input fold. Restarts discard the old frame's time budget.
type Input is Data:
  Input{scene: Scene, held: List<&2, U32>, restart: Bool}

def initial_scene() -> Scene:
  Scene{Simulation.initial(0), 0.82, 1.0, False{}, True{}, True{}, 0, 0.35, 0.0}

def initial() -> State:
  State{initial_scene(), 0n, 0n, 0, 0, []}

def advance_running(+seconds: F32, scene: Scene) -> Scene:
  match scene:
    case Scene{world, +admittance, +coupling, paused, +orbit, trails, seed, yaw, remainder}:
      +elapsed = Math.clamp(seconds, 0.0, 0.05)
      +budget = (remainder + elapsed : F32)
      +steps = F32.to_u32((budget * 120.0 : F32))
      Scene{Simulation.evolve(U32.to_nat(steps), world, Simulation.response(admittance, coupling)),
        admittance, coupling, paused, orbit, trails, seed,
        (yaw + Math.pick(orbit, (0.12 * elapsed : F32), 0.0) : F32),
        Math.max(0.0, (budget - U32.to_f32(steps) / 120.0 : F32))}

def advance(seconds: F32, scene: Scene) -> Scene:
  match scene:
    case Scene{world, admittance, coupling, True{}, orbit, trails, seed, yaw, remainder}:
      Scene{world, admittance, coupling, True{}, orbit, trails, seed, yaw, remainder}
    case Scene{world, admittance, coupling, False{}, orbit, trails, seed, yaw, remainder}:
      advance_running(seconds, Scene{world, admittance, coupling, False{}, orbit, trails, seed, yaw, remainder})

def reseed(+seed: U32, scene: Scene) -> Scene:
  match scene:
    case Scene{_, admittance, coupling, paused, orbit, trails, _, yaw, _}:
      Scene{Simulation.initial(seed), admittance, coupling, paused, orbit, trails, seed, yaw, 0.0}

def burst(scene: Scene) -> Scene:
  match scene:
    case Scene{world, admittance, coupling, paused, orbit, trails, seed, yaw, remainder}:
      Scene{Simulation.burst(world), admittance, coupling, paused, orbit, trails, seed, yaw, remainder}

def lowercase(+code: U32) -> U32:
  Math.word((code >= 65 : U32) && (code <= 90 : U32), (code + 32 : U32), code)

# Live coefficient edits preserve particles, velocities and trail history.
def key(+code: U32, scene: Scene) -> Scene:
  match scene:
    case Scene{world, +admittance, +coupling, +paused, +orbit, +trails, seed, yaw, remainder}:
      +lower = lowercase(code)
      Scene{world,
        Math.clamp((admittance + Math.pick(U32.is_eq(lower, 100), 0.03, 0.0)
          - Math.pick(U32.is_eq(lower, 97), 0.03, 0.0) : F32), 0.55, 1.0),
        Math.pick(U32.is_eq(lower, 49), 0.0,
          Math.pick(U32.is_eq(lower, 50), 1.0,
            Math.pick(U32.is_eq(lower, 51), (0.0 - 1.0 : F32),
              Math.clamp((coupling + Math.pick(U32.is_eq(lower, 101), 0.2, 0.0)
                - Math.pick(U32.is_eq(lower, 113), 0.2, 0.0) : F32), (0.0 - 2.0 : F32), 2.0)))),
        Bool.xor(paused, U32.is_eq(lower, 32)),
        Bool.xor(orbit, U32.is_eq(lower, 111)),
        Bool.xor(trails, U32.is_eq(lower, 116)), seed, yaw, remainder}

def event(event: Event, scene: Scene) -> Maybe<Scene>:
  match event:
    case Close{}:
      None{}
    case Key{27, True{}}:
      None{}
    case Key{114, True{}}:
      Some{initial_scene()}
    case Key{82, True{}}:
      Some{initial_scene()}
    case Key{52, True{}}:
      Some{reseed(0, scene)}
    case Key{53, True{}}:
      Some{reseed(1, scene)}
    case Key{54, True{}}:
      Some{reseed(2, scene)}
    case Key{98, True{}}:
      Some{burst(scene)}
    case Key{66, True{}}:
      Some{burst(scene)}
    case Key{code, True{}}:
      Some{key(code, scene)}
    case _:
      Some{scene}

def contains_key(held: List<&2, U32>, +code: U32) -> Bool:
  match held:
    case []:
      False{}
    case key <> rest:
      U32.is_eq(key, code) || contains_key(rest, code)

def insert_key(already: Bool, code: U32, held: List<&2, U32>) -> List<&2, U32>:
  match already:
    case True{}:
      held
    case False{}:
      code <> held

def keep_key(same: Bool, code: U32, rest: List<&2, U32>) -> List<&2, U32>:
  match same:
    case True{}:
      rest
    case False{}:
      code <> rest

def release(held: List<&2, U32>, +code: U32) -> List<&2, U32>:
  match held:
    case []:
      []
    case +key <> rest:
      keep_key(U32.is_eq(key, code), key, release(rest, code))

# Only coefficient adjustments auto-repeat; toggles, bursts and resets are
# press-edge actions. Native Bend sends repeated downs, not a repeat flag.
def repeatable(+code: U32) -> Bool:
  U32.is_eq(code, 97) || U32.is_eq(code, 100) || U32.is_eq(code, 101) || U32.is_eq(code, 113)

def press_key(blocked: Bool, +code: U32, scene: Scene, +held: List<&2, U32>,
  restart: Bool) -> Maybe<Input>:
  match blocked:
    case True{}:
      Some{Input{scene, held, restart}}
    case False{}:
      +fresh = restart || U32.is_eq(code, 114) || (code >= 52 : U32) && (code <= 54 : U32)
      Maybe.map(&1, Scene, Input,
        next => Input{next, insert_key(contains_key(held, code), code, held), fresh},
        event(Key{code, True{}}, scene))

def press(+code: U32, input: Input) -> Maybe<Input>:
  match input:
    case Input{scene, +held, restart}:
      press_key(contains_key(held, code) && Bool.not(repeatable(code)), code, scene, held, restart)

def input_event(event: Event, input: Input) -> Maybe<Input>:
  match event input:
    case Close{} _:
      None{}
    case Key{code, True{}} _:
      press(lowercase(code), input)
    case Key{code, False{}} Input{scene, held, restart}:
      Some{Input{scene, release(held, lowercase(code)), restart}}
    case _ _:
      Some{input}

def events(pending: List<Event>, input: Input) -> Maybe<Input>:
  match pending:
    case []:
      Some{input}
    case next <> remaining:
      Maybe.bind(&1, Input, Input, input_event(next, input), changed => events(remaining, changed))

def advance_input(seconds: F32, input: Input) -> Input:
  match input:
    case Input{scene, held, +restart}:
      Input{advance(Math.pick(restart, 0.0, seconds), scene), held, restart}

def frame_seconds(first: Bool, now: Nat, last: Nat) -> F32:
  match first:
    case True{}:
      0.0
    case False{}:
      Math.min(0.05, (F32.from_nat(Nat.sub(now, last)) / 1000.0 : F32))

def state_from_input(+now: Nat, epoch: Nat, frames: U32, fps: U32, input: Input) -> State:
  match input:
    case Input{scene, held, _}:
      State{scene, now, epoch, frames, fps, held}

def counted(reset: Bool, +now: Nat, +elapsed: Nat, +frames: U32, previous_fps: U32,
  input: Maybe<Input>, epoch: Nat) -> Maybe<State>:
  match reset:
    case True{}:
      Maybe.map(&1, Input, State, next => state_from_input(now, now, 0,
        F32.to_u32((U32.to_f32(frames) * 1000.0 / Math.max(1.0, F32.from_nat(elapsed)) : F32)), next), input)
    case False{}:
      Maybe.map(&1, Input, State, next => state_from_input(now, epoch, frames, previous_fps, next), input)

def tick(+now: Nat, pending: List<Event>, state: State) -> Maybe<State>:
  match state:
    case State{scene, +last, +epoch, frames, fps, held}:
      +first = Nat.is_eq(last, 0n)
      seconds = frame_seconds(first, now, last)
      +elapsed = Nat.sub(now, epoch)
      counted(first || Nat.is_le(1000n, elapsed), now, elapsed, (frames + 1 : U32), fps,
        Maybe.map(&1, Input, Input, next => advance_input(seconds, next),
          events(pending, Input{scene, held, False{}})), epoch)
