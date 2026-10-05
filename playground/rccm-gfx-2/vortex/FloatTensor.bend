import Base
import ../tensor/Matrix4.bend as Matrix4
import ../tensor/Layout.bend as Layout

# F32 approximation for an illustrative numerical toy.
# Not exact rationals, a physical admissibility certificate, or verified CFD.
type Vector3 is Data:
  Vector3{x: F32, y: F32, z: F32}

def neg(value: F32) -> F32:
  (0.0 - value : F32)

# RCCM-GfX-2 section 3.3: alpha_s^2, 1/alpha_s^2,
# alpha*(v_perp/c), alpha*(t_p*Omega), in time,x,y,z order.
# Caller must supply nonzero phase_speed and admittance, and bounded finite
# inputs (the UI uses admittance 0.55..1). No clamping or singularity fallback.
# Preserve the paper's parentheses; F32 rounding need not match rational
# reassociation in Coefficients.bend.
def matrix(
  +admittance: F32,
  +coupling: F32,
  +phase_speed: F32,
  +relaxation_time: F32,
  velocity: Vector3,
  vorticity: Vector3
) -> Matrix4.Matrix4<F32>:
  match velocity vorticity:
    case Vector3{vx, vy, vz} Vector3{wx, wy, wz}:
      +squared = (admittance * admittance : F32)
      inverse = (1.0 / squared : F32)
      velocity_x = (coupling * (vx / phase_speed : F32) : F32)
      velocity_y = (coupling * (vy / phase_speed : F32) : F32)
      velocity_z = (coupling * (vz / phase_speed : F32) : F32)
      vorticity_x = (coupling * (relaxation_time * wx : F32) : F32)
      vorticity_y = (coupling * (relaxation_time * wy : F32) : F32)
      vorticity_z = (coupling * (relaxation_time * wz : F32) : F32)
      Layout.assemble(~F32, ~neg, squared, inverse,
        velocity_x, velocity_y, velocity_z, vorticity_x, vorticity_y, vorticity_z)

# Return only x,y,z of matrix * [time_component,x,y,z], not the time row.
# A reusable matrix in the caller can be probed with the three spatial bases
# and the time basis to obtain local strain/spin/drift rates.
def apply_spatial(matrix: Matrix4.Matrix4<F32>, +time_component: F32, vector: Vector3) -> Vector3:
  match matrix vector:
    case Matrix4.Matrix4{_, Matrix4.Row4{xt, xx, xy, xz}, Matrix4.Row4{yt, yx, yy, yz}, Matrix4.Row4{zt, zx, zy, zz}} Vector3{+x, +y, +z}:
      result_x = (xt * time_component + xx * x + xy * y + xz * z : F32)
      result_y = (yt * time_component + yx * x + yy * y + yz * z : F32)
      result_z = (zt * time_component + zx * x + zy * y + zz * z : F32)
      Vector3{result_x, result_y, result_z}
