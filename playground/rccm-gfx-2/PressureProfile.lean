import Mathlib.Analysis.SpecialFunctions.Exp

/-!
# RCCM-GfX-2 section 15 scalar transcription

Source commit: 9cb777b2f23b387e875c1a03353a700d41afdb0e
RCCM-GfX-2.tex lines 2074–2078, label eq:dark_energy.
Lean checking: NOT RUN. No installed/pinned Lean/mathlib toolchain.
These declarations state an expression and a proposition; they prove no claim.

TODO[RCCM-004]: reconcile the prose boundary r = ct with the formula.
TODO[RCCM-005]: identify the data/fit provenance.
Units are documented externally; these are scalar magnitudes, not unit-safe types.
-/

namespace RccmDraft

/-- Normalized scalar profile printed in the paper, using the standard exponential. -/
noncomputable def pressureFraction (normalizedRadius : Real) : Real :=
  (1 - Real.exp (-normalizedRadius)) ^ 2

/-- Here scaleLength abbreviates the source product c * t. -/
noncomputable def dynamicPressure
    (radius scaleLength criticalPressure : Real) : Real :=
  criticalPressure * pressureFraction (radius / scaleLength)

/-- Explicit physical input restrictions proposed for this radial scalar slice. -/
def ProfileInputsAdmissible
    (radius scaleLength criticalPressure : Real) : Prop :=
  And (0 <= radius) (And (0 < scaleLength) (0 < criticalPressure))

/-- The printed equality only; input admissibility is a separate predicate above. -/
def PressureProfileAt
    (radius scaleLength criticalPressure pressureValue : Real) : Prop :=
  pressureValue = dynamicPressure radius scaleLength criticalPressure

end RccmDraft
