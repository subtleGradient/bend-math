import Base
import ../vortex/FloatTensor.bend as Tensor
import ../vortex/Math.bend as Math

def zero() -> Tensor.Vector3:
  Tensor.Vector3{0.0, 0.0, 0.0}

def add(left: Tensor.Vector3, right: Tensor.Vector3) -> Tensor.Vector3:
  match left right:
    case Tensor.Vector3{x, y, z} Tensor.Vector3{a, b, c}:
      Tensor.Vector3{(x + a : F32), (y + b : F32), (z + c : F32)}

def sub(left: Tensor.Vector3, right: Tensor.Vector3) -> Tensor.Vector3:
  match left right:
    case Tensor.Vector3{x, y, z} Tensor.Vector3{a, b, c}:
      Tensor.Vector3{(x - a : F32), (y - b : F32), (z - c : F32)}

def scale(+amount: F32, vector: Tensor.Vector3) -> Tensor.Vector3:
  match vector:
    case Tensor.Vector3{x, y, z}:
      Tensor.Vector3{(amount * x : F32), (amount * y : F32), (amount * z : F32)}

def dot(left: Tensor.Vector3, right: Tensor.Vector3) -> F32:
  match left right:
    case Tensor.Vector3{x, y, z} Tensor.Vector3{a, b, c}:
      (x * a + y * b + z * c : F32)

def length_squared(+vector: Tensor.Vector3) -> F32:
  dot(vector, vector)

def limit(+vector: Tensor.Vector3, maximum: F32) -> Tensor.Vector3:
  scale(Math.min(1.0, (maximum / Math.max(0.0001, F32.sqrt(length_squared(vector))) : F32)), vector)
