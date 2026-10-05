# Bend ecosystem findings and actionable gaps

Discovery starts with the user-supplied
[Bend package overview](https://github.com/lilalittle/bend-packages/blob/main/README.md),
not only bend-mathlib. A catalog entry is not the same as an inspected or checked
implementation. These findings are bounded by the packages inspected below.

## What exists

| Candidate | Evidence | Status / suitability |
| --- | --- | --- |
| `bend-kit-bignum@0.1.0.0` | [Rational source](https://github.com/paymog/bend-kit/blob/main/bignum/rational.bend), local resolution `0xbf5d8bf07d7411858acb5142889fc4d7` | Imported, checked and executed here; rational make/read/add/mul/div/neg/show exist. Arithmetic is not missing |
| `bend-mathlib@0.7.2.0/equal.bend` | Published `cong2`, resolved `0x449abff091641d732d7b9f0780df40ae` | Imported and used in a checked generic matrix law |
| `bend-mathlib@0.7.2.0/algebra.bend` | [Abstract algebra lemmas](https://github.com/bendlib/bendlib/blob/main/packages/bend-mathlib/algebra.bend) | Inspected; reassociation/commutation lemmas take operation/law arguments, not a complete rational-field instance |
| `bend-ml-tensor@0.1.2.0` | Hub source `0x48e80e20946abebea50e06561806a40d/main.bend` | Source inspected; `Vec`/`Mat` specialize entries to F32. Catalog advertises tensor.bend while inspected hub source says main.bend; not imported or checked here |
| `bend-tensors@0.0.0.2/bend_tensors.bend` | Hub source `0x39d8166231e68361eb37e8bef9287b8a/bend_tensors.bend` | Source inspected; `Blk` supplies 4x4 operations over F32. Not a drop-in exact rational matrix |
| `bend-ml-tensor-array` | Inspected hub source `0xa78e1f1609ed090d0092c5fff6f9bac7/main.bend` | F32 array backend; catalog/header version/path discrepancy remains unresolved. Not imported |
| `bend-lawful-stdlib@0.1.0.0` | Listed in overview as lawful algebra abstractions | Catalogued only; evaluate before designing a new field interface |

Earlier "no rational/matrix package found" conclusions were based on too narrow a
search. They are superseded: **rational arithmetic and tensor packages exist**.
The narrower problems are scalar generality, proved algebraic coverage, and integration.

## Gap ledger

| ID | Required operation/law | Evidence / scope of search | Current workaround | Minimal upstream proposal | Acceptance criterion |
| --- | --- | --- | --- | --- | --- |
| GAP-TENSOR-001 | Fixed-size matrix over an arbitrary scalar, not only F32 | Two inspected tensor packages above fix F32 | Local generic Matrix4, row product shape | Extract scalar-generic matrix/transpose/map/zip with lawful equality transport; investigate extension of existing package first | Exact rational backend and another scalar instantiate unchanged; transpose involution and shape safety check |
| GAP-TENSOR-002 | Canonical rational validity and universal additive/negation/field laws | Bignum source exposes raw num/den; its inspected LAWS contains concrete rational examples, not a complete field instance | Smart-constructor precondition; concrete rational regression proofs; universal structural proofs only | Validity predicate or certified wrapper plus preservation and laws: add_zero, zero_add, neg_zero, neg_neg, associativity, distributivity, nonzero division | Rules quantified over valid rationals check with no holes/unsafe; malformed denominator not silently admitted |
| GAP-TENSOR-003 | Universal `U = S + A` and `transpose(A) = -A` for this construction | Depends on rational validity/laws in GAP-TENSOR-002 | Checked for one independently specified dense fixture | Prove sector lemmas over an existing lawful scalar interface, then instantiate a certified Rational backend | Check for every valid coefficient input; no finite sample promoted to universal coverage |
| GAP-TENSOR-004 | Real-valued fields, derivatives, tensor covariance and geometry | Not provided by the scalar rational matrix or F32 arrays; no full ecosystem absence claimed | Lean field-generic reference; source-located author questions | Separate tasks for needed analysis/geometry APIs after targeted searches and author choices | Precise domains/operators and bridge to component model; no false claim of continuous physics from matrix tests |
| GAP-TOOL-001 | Proven-kernel recheck | Actual `bend PROOF.bend --verdict` error requires Lean v4.34.0 or BENDTT | Ordinary checker gate, explicitly labeled | Configure the documented kernel toolchain when approved/available | Same proof entry point passes --verdict; retain output/version |

## Source questions are not package gaps

RCCM's meaning of "asymmetric metric", raising/lowering convention, units, physical
parameter restrictions, and derivation of field equations require author/source
decisions. A new library cannot resolve those by choosing defaults.

No package was published and no upstream issue was opened. The rows above are
local, reviewable candidates for that next step.
