-- A claim about natural numbers, followed by a proof.
-- rfl works because both sides compute to the same natural number.
example : (1 : Nat) + 1 = 2 := by
  rfl
