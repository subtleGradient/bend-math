import Mathlib.Data.Real.Basic

/-!
# Bernoulli scalar semantic slice

Fixture, not a transcription of a supplied paper. No physical law is proved here.
Lean checking: NOT RUN; no Lean/mathlib toolchain was available during bootstrap.
TODO[SEM-004]: formalize units, admissibility, fields, and streamline scope.
TODO[SEM-006]: conservation proof work is blocked until its statement is fixed.
-/

namespace PaperMathSemantics

/-- Scalar pressure-form expression; units and physical constraints are external. -/
noncomputable def bernoulliPressure
    (pressure density speed gravitationalAcceleration elevation : Real) : Real :=
  pressure + density * speed ^ 2 / 2 + density * gravitationalAcceleration * elevation

/-- The displayed scalar equation, not a quantified conservation law or its proof. -/
def BernoulliAt
    (pressure density speed gravitationalAcceleration elevation bernoulliConstant : Real) : Prop :=
  bernoulliPressure pressure density speed gravitationalAcceleration elevation =
    bernoulliConstant

end PaperMathSemantics
