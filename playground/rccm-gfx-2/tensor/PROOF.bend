import Base
import bend-kit-bignum@0.1.0.0/rational.bend as Rat
import bend-mathlib@0.7.2.0/equal.bend as MEqual
import ./Matrix4.bend as Matrix
import ./Coefficients.bend as C
import ./Tensor.bend as Tensor
import ./LAWS.bend as Laws

def Laws.transpose_involution(Scalar, matrix):
  match matrix:
    case Matrix.Matrix4{Matrix.Row4{a, b, c, d}, Matrix.Row4{e, f, g, h}, Matrix.Row4{i, j, k, l}, Matrix.Row4{m, n, o, p}}:
      {==}

# Reuse bend-mathlib's two-argument congruence rather than rebuild equality logic.
def Laws.zip_congr(Scalar, operation, left, left_equal, right, right_equal, left_proof, right_proof):
  MEqual.cong2(Matrix.Matrix4<Scalar>, Matrix.Matrix4<Scalar>, Matrix.Matrix4<Scalar>,
    Matrix.zip_with(~Scalar, ~operation), left, left_equal, right, right_equal,
    left_proof, right_proof)

def Laws.symmetric_sector_is_symmetric(coefficients):
  match coefficients:
    case C.Coefficients{squared, inverse, _, _}:
      {==}

def Laws.fixture_coefficients():
  {==}

def Laws.fixture_matrix():
  {==}

def Laws.fixture_decomposition():
  {==}

def Laws.fixture_antisymmetric():
  {==}

def Laws.zero_admittance_rejected():
  {==}

def Laws.zero_phase_speed_rejected():
  {==}
