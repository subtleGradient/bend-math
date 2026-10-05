import Base
import bend-kit-bignum@0.1.0.0/rational.bend as Rat
import ./Matrix4.bend as Matrix
import ./Coefficients.bend as C
import ./Tensor.bend as Tensor
import ./Fixtures.bend as Fixture

# Universal structural claims, independent of a scalar field implementation.
law transpose_involution:
  for -Scalar: Data
  for +matrix: Matrix.Matrix4<Scalar>
  {Matrix.transpose(Scalar, Matrix.transpose(Scalar, matrix)) == matrix : Matrix.Matrix4<Scalar>}

law zip_congr:
  for ~Scalar: Data
  for ~operation: Scalar -> Scalar -> Scalar
  for -left: Matrix.Matrix4<Scalar>
  for -left_equal: Matrix.Matrix4<Scalar>
  for -right: Matrix.Matrix4<Scalar>
  for -right_equal: Matrix.Matrix4<Scalar>
  for left_proof: {left == left_equal : Matrix.Matrix4<Scalar>}
  for right_proof: {right == right_equal : Matrix.Matrix4<Scalar>}
  {Matrix.zip_with(~Scalar, ~operation, left, right) == Matrix.zip_with(~Scalar, ~operation, left_equal, right_equal) : Matrix.Matrix4<Scalar>}

law symmetric_sector_is_symmetric:
  for +coefficients: C.Coefficients
  {Matrix.transpose(Rat.Rational, Tensor.symmetric_sector(coefficients)) == Tensor.symmetric_sector(coefficients) : Matrix.Matrix4<Rat.Rational>}

# Concrete regression proofs: these do NOT quantify over all rational inputs.
law fixture_coefficients:
  {C.from_parameters(Fixture.parameters()) == Some{Fixture.coefficients()} : Maybe<&2, C.Coefficients>}

law fixture_matrix:
  {Tensor.from_parameters(Fixture.parameters()) == Some{Fixture.expected_matrix()} : Maybe<&2, Matrix.Matrix4<Rat.Rational>>}

law fixture_decomposition:
  {Tensor.add(Tensor.symmetric_sector(Fixture.coefficients()), Tensor.antisymmetric_sector(Fixture.coefficients())) == Fixture.expected_matrix() : Matrix.Matrix4<Rat.Rational>}

law fixture_antisymmetric:
  {Matrix.transpose(Rat.Rational, Tensor.antisymmetric_sector(Fixture.coefficients())) == Tensor.negate(Tensor.antisymmetric_sector(Fixture.coefficients())) : Matrix.Matrix4<Rat.Rational>}

law zero_admittance_rejected:
  {Tensor.from_parameters(Fixture.zero_admittance()) == None{} : Maybe<&2, Matrix.Matrix4<Rat.Rational>>}

law zero_phase_speed_rejected:
  {Tensor.from_parameters(Fixture.zero_phase_speed()) == None{} : Maybe<&2, Matrix.Matrix4<Rat.Rational>>}
