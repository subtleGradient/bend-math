import Base
import bend-kit-bignum@0.1.0.0/rational.bend as Rat
import ./Matrix4.bend as Matrix
import ./Coefficients.bend as C

# Source: RCCM-GfX-2.tex, section 3.3, eq:unified_matrix, lines 172-177
# at commit 9cb777b2f23b387e875c1a03353a700d41afdb0e. Axis order: time,x,y,z.
# This is the displayed component matrix, not a proved physical metric.
def assemble(coefficients: C.Coefficients) -> Matrix.Matrix4<Rat.Rational>:
  match coefficients:
    case C.Coefficients{squared, +inverse, C.Vector3{+velocity_x, +velocity_y, +velocity_z}, C.Vector3{+vorticity_x, +vorticity_y, +vorticity_z}}:
      Matrix.Matrix4{
        Matrix.Row4{Rat.Rational.neg(squared), Rat.Rational.neg(velocity_x), Rat.Rational.neg(velocity_y), Rat.Rational.neg(velocity_z)},
        Matrix.Row4{velocity_x, inverse, Rat.Rational.neg(vorticity_z), vorticity_y},
        Matrix.Row4{velocity_y, vorticity_z, inverse, Rat.Rational.neg(vorticity_x)},
        Matrix.Row4{velocity_z, Rat.Rational.neg(vorticity_y), vorticity_x, inverse}
      }

def symmetric_sector(coefficients: C.Coefficients) -> Matrix.Matrix4<Rat.Rational>:
  match coefficients:
    case C.Coefficients{squared, +inverse, _, _}:
      Matrix.Matrix4{
        Matrix.Row4{Rat.Rational.neg(squared), C.whole(0), C.whole(0), C.whole(0)},
        Matrix.Row4{C.whole(0), inverse, C.whole(0), C.whole(0)},
        Matrix.Row4{C.whole(0), C.whole(0), inverse, C.whole(0)},
        Matrix.Row4{C.whole(0), C.whole(0), C.whole(0), inverse}
      }

def antisymmetric_sector(coefficients: C.Coefficients) -> Matrix.Matrix4<Rat.Rational>:
  match coefficients:
    case C.Coefficients{_, _, C.Vector3{+velocity_x, +velocity_y, +velocity_z}, C.Vector3{+vorticity_x, +vorticity_y, +vorticity_z}}:
      Matrix.Matrix4{
        Matrix.Row4{C.whole(0), Rat.Rational.neg(velocity_x), Rat.Rational.neg(velocity_y), Rat.Rational.neg(velocity_z)},
        Matrix.Row4{velocity_x, C.whole(0), Rat.Rational.neg(vorticity_z), vorticity_y},
        Matrix.Row4{velocity_y, vorticity_z, C.whole(0), Rat.Rational.neg(vorticity_x)},
        Matrix.Row4{velocity_z, Rat.Rational.neg(vorticity_y), vorticity_x, C.whole(0)}
      }

def add(left: Matrix.Matrix4<Rat.Rational>, right: Matrix.Matrix4<Rat.Rational>) -> Matrix.Matrix4<Rat.Rational>:
  Matrix.zip_with(~Rat.Rational, ~Rat.Rational.add, left, right)

def negate(matrix: Matrix.Matrix4<Rat.Rational>) -> Matrix.Matrix4<Rat.Rational>:
  Matrix.map(~Rat.Rational, ~Rat.Rational.neg, matrix)

def finish(coefficients: Maybe<&2, C.Coefficients>) -> Maybe<&2, Matrix.Matrix4<Rat.Rational>>:
  match coefficients:
    case Some{value}:
      Some{assemble(value)}
    case None{}:
      None{}

def from_parameters(parameters: C.Parameters) -> Maybe<&2, Matrix.Matrix4<Rat.Rational>>:
  finish(C.from_parameters(parameters))
