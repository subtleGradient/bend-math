import Base

def pick(condition: Bool, yes: F32, no: F32) -> F32:
  match condition:
    case True{}:
      yes
    case False{}:
      no

def word(condition: Bool, yes: U32, no: U32) -> U32:
  match condition:
    case True{}:
      yes
    case False{}:
      no

def min(+left: F32, +right: F32) -> F32:
  pick((left < right : F32), left, right)

def max(+left: F32, +right: F32) -> F32:
  pick((left > right : F32), left, right)

def clamp(value: F32, low: F32, high: F32) -> F32:
  min(high, max(low, value))

def pack(red: F32, green: F32, blue: F32) -> U32:
  (F32.to_u32((255.0 * clamp(red, 0.0, 1.0) : F32)) << 16n
    .|. F32.to_u32((255.0 * clamp(green, 0.0, 1.0) : F32)) << 8n
    .|. F32.to_u32((255.0 * clamp(blue, 0.0, 1.0) : F32)) : U32)

def tone(+value: F32) -> F32:
  F32.sqrt((value / (1.0 + value) : F32))
