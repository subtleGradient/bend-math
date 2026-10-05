import Base
import ./Matrix4.bend as Matrix4

# RCCM-GfX-2 section 3.3, eq:unified_matrix; axis order: time,x,y,z.
# Shared displayed component layout, not a claim of physical metric validity.
# Inputs are already-scaled coefficients; this function only places their signs.
def assemble(
  ~Scalar: Data,
  ~neg: Scalar -> Scalar,
  squared: Scalar,
  +inverse: Scalar,
  +velocity_x: Scalar,
  +velocity_y: Scalar,
  +velocity_z: Scalar,
  +vorticity_x: Scalar,
  +vorticity_y: Scalar,
  +vorticity_z: Scalar
) -> Matrix4.Matrix4<Scalar>:
  Matrix4.Matrix4{
    Matrix4.Row4{neg(squared), neg(velocity_x), neg(velocity_y), neg(velocity_z)},
    Matrix4.Row4{velocity_x, inverse, neg(vorticity_z), vorticity_y},
    Matrix4.Row4{velocity_y, vorticity_z, inverse, neg(vorticity_x)},
    Matrix4.Row4{velocity_z, neg(vorticity_y), vorticity_x, inverse}
  }
