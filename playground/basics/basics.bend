import Base

# A claim about natural numbers, followed by a proof.
# {==} works because both sides compute to the same natural number.
def one_plus_one() -> {Nat.add(1n, 1n) == 2n : Nat}:
  {==}
