import Base
import ./Simulation.bend as Sim
import ./Grid.bend as Grid
import ./Diagnostics.bend as Diag
import ../vortex/Math.bend as Math

type Scene is Data:
  Scene{world: Sim.World, baseline: Diag.Stats, stats: Diag.Stats,
    paused: Bool, seed: U32, slice: U32, mode: U32, budget: F32}

type State is Data:
  State{scene: Scene, last: Nat, held: List<&2, U32>}

type Input is Data:
  Input{scene: Scene, held: List<&2, U32>, discard: Bool}

def world_grid(world: Sim.World) -> Grid.Grid:
  match world:
    case Sim.World{grid, _}:
      grid

def seeded(+seed: U32, paused: Bool, slice: U32, mode: U32) -> Scene:
  +world = Sim.initial(seed)
  +stats = Diag.measure(world_grid(world))
  Scene{world, stats, stats, paused, seed, slice, mode, 0.0}

def initial() -> State:
  State{seeded(0, False{}, 8, 0), 0n, []}

def stepped(scene: Scene) -> Scene:
  match scene:
    case Scene{world, baseline, _, paused, seed, slice, mode, budget}:
      +next = Sim.step(world)
      Scene{next, baseline, Diag.measure(world_grid(next)), paused, seed, slice, mode, budget}

# Check every fixed step, including the starting state. Invalid values remain
# visible; never clip or silently replace a solver state.
def allowed_step(valid: Bool, scene: Scene) -> Scene:
  match valid:
    case True{}:
      stepped(scene)
    case False{}:
      scene

def step(+scene: Scene) -> Scene:
  match scene:
    case Scene{_, _, stats, _, _, _, _, _}:
      allowed_step(Diag.admissible(stats), scene)

def single(paused: Bool, scene: Scene) -> Scene:
  match paused:
    case True{}:
      step(scene)
    case False{}:
      scene

def action(code: U32, scene: Scene) -> Scene:
  match code scene:
    case 32 Scene{world, baseline, stats, paused, seed, slice, mode, _}:
      Scene{world, baseline, stats, Bool.not(paused), seed, slice, mode, 0.0}
    case 110 Scene{world, baseline, stats, +paused, seed, slice, mode, budget}:
      single(paused, Scene{world, baseline, stats, paused, seed, slice, mode, budget})
    case 114 Scene{_, _, _, paused, seed, slice, mode, _}:
      seeded(seed, paused, slice, mode)
    case 49 Scene{_, _, _, paused, _, slice, mode, _}:
      seeded(0, paused, slice, mode)
    case 50 Scene{_, _, _, paused, _, slice, mode, _}:
      seeded(1, paused, slice, mode)
    case 51 Scene{_, _, _, paused, _, slice, mode, _}:
      seeded(2, paused, slice, mode)
    case 91 Scene{world, baseline, stats, paused, seed, slice, mode, budget}:
      Scene{world, baseline, stats, paused, seed, ((slice + 15) % 16 : U32), mode, budget}
    case 93 Scene{world, baseline, stats, paused, seed, slice, mode, budget}:
      Scene{world, baseline, stats, paused, seed, ((slice + 1) % 16 : U32), mode, budget}
    case 118 Scene{world, baseline, stats, paused, seed, slice, mode, budget}:
      Scene{world, baseline, stats, paused, seed, slice, ((mode + 1) % 3 : U32), budget}
    case _ _:
      scene

# Native key-down repeat has no separate repeat flag. Track normalized keys
# across frames, following particles/Controls; only slice keys auto-repeat.
def lowercase(+code: U32) -> U32:
  Math.word((code >= 65 : U32) && (code <= 90 : U32), (code + 32 : U32), code)

def contains(held: List<&2, U32>, +code: U32) -> Bool:
  match held:
    case []:
      False{}
    case key <> rest:
      U32.is_eq(key, code) || contains(rest, code)

def insert(already: Bool, code: U32, held: List<&2, U32>) -> List<&2, U32>:
  match already:
    case True{}:
      held
    case False{}:
      code <> held

def keep(same: Bool, code: U32, rest: List<&2, U32>) -> List<&2, U32>:
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
      keep(U32.is_eq(key, code), key, release(rest, code))

def press_allowed(blocked: Bool, +code: U32, scene: Scene,
  +held: List<&2, U32>, discard: Bool) -> Maybe<Input>:
  match blocked:
    case True{}:
      Some{Input{scene, held, discard}}
    case False{}:
      Some{Input{action(code, scene),
        insert(contains(held, code), code, held),
        discard || U32.is_eq(code, 32) || U32.is_eq(code, 114) ||
          ((code >= 49 : U32) && (code <= 51 : U32))}}

def press(+code: U32, input: Input) -> Maybe<Input>:
  match input:
    case Input{scene, +held, discard}:
      press_allowed(contains(held, code) &&
        Bool.not(U32.is_eq(code, 91) || U32.is_eq(code, 93)),
        code, scene, held, discard)

def event(event: Event, input: Input) -> Maybe<Input>:
  match event input:
    case Close{} _:
      None{}
    case Key{27, True{}} _:
      None{}
    case Key{code, True{}} _:
      press(lowercase(code), input)
    case Key{code, False{}} Input{scene, held, discard}:
      Some{Input{scene, release(held, lowercase(code)), discard}}
    case _ _:
      Some{input}

def events(pending: List<Event>, input: Input) -> Maybe<Input>:
  match pending:
    case []:
      Some{input}
    case next <> rest:
      Maybe.bind(&1, Input, Input, event(next, input), changed => events(rest, changed))

def spend(fuel: Nat, scene: Scene) -> Scene:
  match fuel:
    case 0n:
      scene
    case 1n+rest:
      spend(rest, step(scene))

def running(seconds: F32, scene: Scene) -> Scene:
  match scene:
    case Scene{+world, baseline, stats, paused, seed, slice, mode, budget}:
      +dt = Sim.timestep(world_grid(world))
      +total = (budget + Math.clamp(seconds, 0.0, 0.1) : F32)
      +count = F32.to_u32((total / dt : F32))
      spend(U32.to_nat(count), Scene{world, baseline, stats, paused, seed, slice, mode,
        Math.max(0.0, (total - U32.to_f32(count) * dt : F32))})

def advance_valid(valid: Bool, seconds: F32, scene: Scene) -> Scene:
  match valid:
    case True{}:
      running(seconds, scene)
    case False{}:
      scene

def advance(seconds: F32, scene: Scene) -> Scene:
  match scene:
    case Scene{world, baseline, stats, True{}, seed, slice, mode, _}:
      Scene{world, baseline, stats, True{}, seed, slice, mode, 0.0}
    case Scene{world, baseline, +stats, False{}, seed, slice, mode, budget}:
      advance_valid(Diag.admissible(stats), seconds,
        Scene{world, baseline, stats, False{}, seed, slice, mode, budget})

def finish(+now: Nat, seconds: F32, input: Input) -> State:
  match input:
    case Input{scene, held, discard}:
      State{advance(Math.pick(discard, 0.0, seconds), scene), now, held}

def tick(+now: Nat, pending: List<Event>, state: State) -> Maybe<State>:
  match state:
    case State{scene, +last, held}:
      seconds = Math.pick(Nat.is_eq(last, 0n), 0.0,
        (F32.from_nat(Nat.sub(now, last)) / 1000.0 : F32))
      Maybe.map(&1, Input, State, next => finish(now, seconds, next),
        events(pending, Input{scene, held, False{}}))
