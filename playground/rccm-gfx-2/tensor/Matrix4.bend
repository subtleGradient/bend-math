import Base

# The inspected hub tensor APIs fix entries to F32. This small generic product
# preserves exactly four rows/columns and can be extracted as a reusable package.
type Row4<-Scalar: Data> is Data:
  Row4{first: Scalar, second: Scalar, third: Scalar, fourth: Scalar}

type Matrix4<-Scalar: Data> is Data:
  Matrix4{first: Row4<Scalar>, second: Row4<Scalar>, third: Row4<Scalar>, fourth: Row4<Scalar>}

def transpose(-Scalar: Data, matrix: Matrix4<Scalar>) -> Matrix4<Scalar>:
  match matrix:
    case Matrix4{Row4{a, b, c, d}, Row4{e, f, g, h}, Row4{i, j, k, l}, Row4{m, n, o, p}}:
      Matrix4{Row4{a, e, i, m}, Row4{b, f, j, n}, Row4{c, g, k, o}, Row4{d, h, l, p}}

def zip_row(~Scalar: Data, ~operation: Scalar -> Scalar -> Scalar, left: Row4<Scalar>, right: Row4<Scalar>) -> Row4<Scalar>:
  match left right:
    case Row4{a, b, c, d} Row4{e, f, g, h}:
      ae bf = operation(a, e) operation(b, f)
      cg dh = operation(c, g) operation(d, h)
      Row4{ae, bf, cg, dh}

# Pointwise operation, not matrix multiplication.
def zip_with(~Scalar: Data, ~operation: Scalar -> Scalar -> Scalar, left: Matrix4<Scalar>, right: Matrix4<Scalar>) -> Matrix4<Scalar>:
  match left right:
    case Matrix4{a, b, c, d} Matrix4{e, f, g, h}:
      ae bf = zip_row(~Scalar, ~operation, a, e) zip_row(~Scalar, ~operation, b, f)
      cg dh = zip_row(~Scalar, ~operation, c, g) zip_row(~Scalar, ~operation, d, h)
      Matrix4{ae, bf, cg, dh}

def map_row(~Scalar: Data, ~operation: Scalar -> Scalar, row: Row4<Scalar>) -> Row4<Scalar>:
  match row:
    case Row4{a, b, c, d}:
      oa ob = operation(a) operation(b)
      oc od = operation(c) operation(d)
      Row4{oa, ob, oc, od}

def map(~Scalar: Data, ~operation: Scalar -> Scalar, matrix: Matrix4<Scalar>) -> Matrix4<Scalar>:
  match matrix:
    case Matrix4{a, b, c, d}:
      oa ob = map_row(~Scalar, ~operation, a) map_row(~Scalar, ~operation, b)
      oc od = map_row(~Scalar, ~operation, c) map_row(~Scalar, ~operation, d)
      Matrix4{oa, ob, oc, od}
