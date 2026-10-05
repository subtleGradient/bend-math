import Base
import ./Math.bend as Math
import ./Field.bend as Field

type View is Data:
  View{spin_phase: F32, drift_phase: F32, yaw: F32, admittance: F32, coupling: F32,
    paused: Bool, orbit: Bool, cutaway: Bool}

type State is Data:
  State{view: View, last_frame: Nat, fps_epoch: Nat, frames: U32, fps: U32}

def initial_view() -> View:
  View{0.0, 0.0, 0.35, 0.82, 1.0, False{}, True{}, False{}}

def initial() -> State:
  State{initial_view(), 0n, 0n, 0, 0}

def advance_with_rates(+seconds: F32, view: View, rates: Field.Rates) -> View:
  match view rates:
    case View{spin_phase, drift_phase, yaw, admittance, coupling, +paused, +orbit, cutaway} Field.Rates{_, spin, drift}:
      +elapsed = Math.pick(paused, 0.0, seconds)
      View{(spin_phase + spin * elapsed : F32), (drift_phase + drift * elapsed : F32),
        (yaw + Math.pick(orbit, (0.14 * elapsed : F32), 0.0) : F32),
        admittance, coupling, paused, orbit, cutaway}

def advance(seconds: F32, +view: View) -> View:
  match view:
    case View{_, _, _, admittance, coupling, _, _, _}:
      advance_with_rates(seconds, view, Field.rates(admittance, coupling))

# Key codes are ASCII; uppercase aliases support Shift/Caps Lock.
def key(+code: U32, view: View) -> Maybe<View>:
  match view:
    case View{spin_phase, drift_phase, yaw, +admittance, +coupling, +paused, +orbit, +cutaway}:
      +lower = Math.word(((code >= 65) && (code <= 90) : U32), (code + 32 : U32), code)
      Some{View{
        spin_phase,
        drift_phase,
        yaw,
        Math.clamp((admittance + Math.pick(U32.is_eq(lower, 100), 0.03, 0.0) - Math.pick(U32.is_eq(lower, 97), 0.03, 0.0) : F32), 0.55, 1.0),
        Math.pick(U32.is_eq(lower, 49), 0.0,
          Math.pick(U32.is_eq(lower, 50), 1.0,
            Math.pick(U32.is_eq(lower, 51), (0.0 - 1.5 : F32),
              Math.clamp((coupling + Math.pick(U32.is_eq(lower, 101), 0.2, 0.0) - Math.pick(U32.is_eq(lower, 113), 0.2, 0.0) : F32), (0.0 - 2.0 : F32), 2.0)))),
        Bool.xor(paused, U32.is_eq(lower, 32)),
        Bool.xor(orbit, U32.is_eq(lower, 111)),
        Bool.xor(cutaway, U32.is_eq(lower, 99))
      }}

def event(event: Event, view: View) -> Maybe<View>:
  match event:
    case Close{}:
      None{}
    case Key{27, True{}}:
      None{}
    case Key{114, True{}}:
      Some{initial_view()}
    case Key{82, True{}}:
      Some{initial_view()}
    case Key{code, True{}}:
      key(code, view)
    case _:
      Some{view}

def events(pending: List<Event>, view: View) -> Maybe<View>:
  match pending:
    case []:
      Some{view}
    case next_event <> remaining:
      Maybe.bind(&1, View, View, event(next_event, view), next => events(remaining, next))

def counted(reset: Bool, +now: Nat, +elapsed: Nat, +frames: U32, previous_fps: U32, view: Maybe<View>, epoch: Nat) -> Maybe<State>:
  match reset:
    case True{}:
      Maybe.map(&1, View, State,
        next => State{next, now, now, 0,
          F32.to_u32((U32.to_f32(frames) * 1000.0 / Math.max(1.0, F32.from_nat(elapsed)) : F32))},
        view)
    case False{}:
      Maybe.map(&1, View, State, next => State{next, now, epoch, frames, previous_fps}, view)

def tick(+now: Nat, pending: List<Event>, state: State) -> Maybe<State>:
  match state:
    case State{view, last_frame, +epoch, frames, fps}:
      seconds = Math.min(0.1, (F32.from_nat(Nat.sub(now, last_frame)) / 1000.0 : F32))
      +elapsed = Nat.sub(now, epoch)
      counted(Nat.is_le(1000n, elapsed), now, elapsed, (frames + 1 : U32), fps,
        events(pending, advance(seconds, view)), epoch)
