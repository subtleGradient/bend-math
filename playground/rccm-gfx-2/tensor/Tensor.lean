import Mathlib

/-!
# Supporting reference for the Bend RCCM matrix

Source: RCCM-GfX-2.tex, commit 9cb777b2f23b387e875c1a03353a700d41afdb0e,
section 3.3, eq:unified_matrix, lines 172–177.

NOT TYPECHECKED here: Lean/mathlib are unavailable. No proof is claimed.
The generic field reference can be instantiated with Rat or Real. The Bend
implementation currently specializes the scalar arithmetic to exact rationals.
Matrix entries are in axis order time, x, y, z. Units remain external.
-/

namespace RccmTensor

structure Parameters (Scalar : Type) where
  scalarAdmittance : Scalar
  shearCoupling : Scalar
  phaseSpeed : Scalar
  relaxationTime : Scalar
  transverseVelocity : Fin 3 -> Scalar
  internalVorticity : Fin 3 -> Scalar

structure Coefficients (Scalar : Type) where
  admittanceSquared : Scalar
  inverseAdmittanceSquared : Scalar
  velocityCoupling : Fin 3 -> Scalar
  vorticityCoupling : Fin 3 -> Scalar

def assemble {Scalar : Type} [Neg Scalar]
    (coefficients : Coefficients Scalar) : Matrix (Fin 4) (Fin 4) Scalar :=
  !![-coefficients.admittanceSquared,
      -coefficients.velocityCoupling 0,
      -coefficients.velocityCoupling 1,
      -coefficients.velocityCoupling 2;
      coefficients.velocityCoupling 0,
      coefficients.inverseAdmittanceSquared,
      -coefficients.vorticityCoupling 2,
      coefficients.vorticityCoupling 1;
      coefficients.velocityCoupling 1,
      coefficients.vorticityCoupling 2,
      coefficients.inverseAdmittanceSquared,
      -coefficients.vorticityCoupling 0;
      coefficients.velocityCoupling 2,
      -coefficients.vorticityCoupling 1,
      coefficients.vorticityCoupling 0,
      coefficients.inverseAdmittanceSquared]

def fromParameters {Scalar : Type} [Field Scalar] [DecidableEq Scalar]
    (parameters : Parameters Scalar) : Option (Matrix (Fin 4) (Fin 4) Scalar) :=
  if parameters.scalarAdmittance = 0 then
    none
  else if parameters.phaseSpeed = 0 then
    none
  else
    some (assemble {
      admittanceSquared := parameters.scalarAdmittance * parameters.scalarAdmittance
      inverseAdmittanceSquared := 1 /
        (parameters.scalarAdmittance * parameters.scalarAdmittance)
      velocityCoupling := fun axis =>
        (parameters.shearCoupling / parameters.phaseSpeed) * parameters.transverseVelocity axis
      vorticityCoupling := fun axis =>
        (parameters.shearCoupling * parameters.relaxationTime) * parameters.internalVorticity axis
    })

end RccmTensor
