import Base
import bend-kit-bignum@0.1.0.0/bigint.bend as Big
import bend-kit-bignum@0.1.0.0/rational.bend as Rat
import ./Matrix4.bend as Matrix
import ./Coefficients.bend as C

# Independent expected-value fixture builder, NOT a general rational constructor.
# All calls below have a positive denominator and coprime numerator/denominator.
# Production callers should use Rational.make/read.
def literal(numerator: U32, denominator: U32) -> Rat.Rational:
  Rat.Rational{Big.BigInt.from_u32(numerator), Big.BigInt.from_u32(denominator)}

# Synthetic algebraic inputs, not measured RCCM quantities.
def parameters() -> C.Parameters:
  C.Parameters{
    literal(1, 2), literal(1, 2), C.whole(10), C.whole(2),
    C.Vector3{C.whole(2), C.whole(4), C.whole(6)},
    C.Vector3{C.whole(5), C.whole(7), C.whole(11)}
  }

def coefficients() -> C.Coefficients:
  C.Coefficients{
    literal(1, 4), C.whole(4),
    C.Vector3{literal(1, 10), literal(1, 5), literal(3, 10)},
    C.Vector3{C.whole(5), C.whole(7), C.whole(11)}
  }

# All 16 entries independently spelled out to catch placement/sign mistakes.
def expected_matrix() -> Matrix.Matrix4<Rat.Rational>:
  Matrix.Matrix4{
    Matrix.Row4{Rat.Rational.neg(literal(1, 4)), Rat.Rational.neg(literal(1, 10)), Rat.Rational.neg(literal(1, 5)), Rat.Rational.neg(literal(3, 10))},
    Matrix.Row4{literal(1, 10), C.whole(4), Rat.Rational.neg(C.whole(11)), C.whole(7)},
    Matrix.Row4{literal(1, 5), C.whole(11), C.whole(4), Rat.Rational.neg(C.whole(5))},
    Matrix.Row4{literal(3, 10), Rat.Rational.neg(C.whole(7)), C.whole(5), C.whole(4)}
  }

def zero_admittance() -> C.Parameters:
  C.Parameters{C.whole(0), C.whole(1), C.whole(1), C.whole(1),
    C.Vector3{C.whole(0), C.whole(0), C.whole(0)},
    C.Vector3{C.whole(0), C.whole(0), C.whole(0)}}

def zero_phase_speed() -> C.Parameters:
  C.Parameters{C.whole(1), C.whole(1), C.whole(0), C.whole(1),
    C.Vector3{C.whole(0), C.whole(0), C.whole(0)},
    C.Vector3{C.whole(0), C.whole(0), C.whole(0)}}
