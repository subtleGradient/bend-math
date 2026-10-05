import Base
import ./FloatTensor.bend as Tensor
import ./Controls.bend as Controls
import ./Field.bend as Field

# Structural control claims only. F32 operations are opaque to the current
# checker, so numeric behavior belongs to runtime Check.bend, not fake rfl proofs.
law key_release_does_not_toggle:
  {Controls.event(Key{32, False{}}, Controls.initial_view()) ==
    Some{Controls.initial_view()} : Maybe<Controls.View>}

law escape_exits:
  {Controls.event(Key{27, True{}}, Controls.initial_view()) == None{} : Maybe<Controls.View>}

law reset_restores_defaults:
  {Controls.event(Key{114, True{}}, Controls.View{20.0, 10.0, 2.0, 1.0, 0.0, True{}, False{}, True{}}) ==
    Some{Controls.initial_view()} : Maybe<Controls.View>}
