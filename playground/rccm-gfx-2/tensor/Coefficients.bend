import Base
import bend-kit-bignum@0.1.0.0/bigint.bend as Big
import bend-kit-bignum@0.1.0.0/rational.bend as Rat

# Exact rational specialization of RCCM-GfX-2 section 3.3.
# Rational inputs are not all real inputs; no floating-point approximation here.
# Use the package's smart constructors/readers, not unnormalized raw Rational.
type Vector3 is Data:
  Vector3{x: Rat.Rational, y: Rat.Rational, z: Rat.Rational}

type Parameters is Data:
  Parameters{
    scalar_admittance: Rat.Rational,
    shear_coupling: Rat.Rational,
    phase_speed: Rat.Rational,
    relaxation_time: Rat.Rational,
    transverse_velocity: Vector3,
    internal_vorticity: Vector3
  }

type Coefficients is Data:
  Coefficients{
    admittance_squared: Rat.Rational,
    inverse_admittance_squared: Rat.Rational,
    velocity_coupling: Vector3,
    vorticity_coupling: Vector3
  }

def whole(value: U32) -> Rat.Rational:
  Rat.Rational.from_bigint(Big.BigInt.from_u32(value))

def scale_vector(+factor: Rat.Rational, vector: Vector3) -> Vector3:
  match vector:
    case Vector3{x, y, z}:
      scaled_x scaled_y = Rat.Rational.mul(factor, x) Rat.Rational.mul(factor, y)
      Vector3{scaled_x, scaled_y, Rat.Rational.mul(factor, z)}

def finish(
  admittance_squared: Rat.Rational,
  inverse_squared: Maybe<&2, Rat.Rational>,
  velocity_scale: Maybe<&2, Rat.Rational>,
  rotation_scale: Rat.Rational,
  velocity: Vector3,
  vorticity: Vector3
) -> Maybe<&2, Coefficients>:
  match inverse_squared velocity_scale:
    case Some{inverse} Some{scale}:
      velocity_coupling vorticity_coupling = scale_vector(scale, velocity) scale_vector(rotation_scale, vorticity)
      Some{Coefficients{admittance_squared, inverse, velocity_coupling, vorticity_coupling}}
    case _ _:
      None{}

# alpha_s^2, 1/alpha_s^2, alpha*v/c, alpha*t_p*Omega.
# A zero alpha_s or c returns None instead of inventing a singular value.
# This is algebraic construction, not enforcement of every physical constraint.
def from_parameters(parameters: Parameters) -> Maybe<&2, Coefficients>:
  match parameters:
    case Parameters{+admittance, +coupling, phase_speed, relaxation_time, velocity, vorticity}:
      +squared = Rat.Rational.mul(admittance, admittance)
      inverse velocity_scale = Rat.Rational.div(whole(1), squared) Rat.Rational.div(coupling, phase_speed)
      finish(squared, inverse, velocity_scale,
        Rat.Rational.mul(coupling, relaxation_time), velocity, vorticity)
