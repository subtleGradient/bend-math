import Base
import bend-kit-bignum@0.1.0.0/rational.bend as Rat
import ./Matrix4.bend as Matrix
import ./Tensor.bend as Tensor
import ./Fixtures.bend as Fixture

def show_row(row: Matrix.Row4<Rat.Rational>) -> String:
  match row:
    case Matrix.Row4{a, b, c, d}:
      "[" ++ Rat.Rational.show(a) ++ ", " ++ Rat.Rational.show(b) ++ ", " ++ Rat.Rational.show(c) ++ ", " ++ Rat.Rational.show(d) ++ "]"

def show_matrix(matrix: Matrix.Matrix4<Rat.Rational>) -> String:
  match matrix:
    case Matrix.Matrix4{a, b, c, d}:
      show_row(a) ++ "\n" ++ show_row(b) ++ "\n" ++ show_row(c) ++ "\n" ++ show_row(d)

def show_result(result: Maybe<&2, Matrix.Matrix4<Rat.Rational>>) -> String:
  match result:
    case Some{matrix}:
      show_matrix(matrix)
    case None{}:
      "Undefined: scalar admittance or phase speed is zero."

def main() -> IO(Unit):
  IO.print(show_result(Tensor.from_parameters(Fixture.parameters())))
