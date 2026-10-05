# The asymmetric tensor, in Bend 2

This is an executable, **exact rational specialization** of the paper's section
3.3 component matrix. It is not an approximation using floats, not all real-valued
fields, and not a proof of the matrix's proposed physical interpretations.

Source: [RCCM-GfX-2.tex lines 172–177](https://github.com/subtleGradient/rccm/blob/9cb777b2f23b387e875c1a03353a700d41afdb0e/RCCM-GfX-2.tex#L172-L177),
commit `9cb777b2f23b387e875c1a03353a700d41afdb0e`, `eq:unified_matrix`.

## Run it

From this directory, with Bend 2.0.35:

```sh
bend Demo.bend
bend PROOF.bend --check-only
bend PROOF.bend
```

The demo prints:

```text
[-1/4, -1/10, -1/5, -3/10]
[1/10, 4, -11, 7]
[1/5, 11, 4, -5]
[3/10, -7, 5, 4]
```

These are synthetic inputs to exercise all 16 entries, not measured physical data.
No physical admissibility of this fixture is asserted.

## What the code says

Axis order is **time, x, y, z**. Using descriptive shorthand:

```text
admittanceSquared = scalarAdmittance * scalarAdmittance
inverseAdmittanceSquared = 1 / admittanceSquared
velocityCoupling = (shearCoupling / phaseSpeed) * transverseVelocity
vorticityCoupling = (shearCoupling * relaxationTime) * internalVorticity

[
  [-admittanceSquared, -velocityX, -velocityY, -velocityZ],
  [ velocityX, inverseAdmittanceSquared, -vorticityZ,  vorticityY],
  [ velocityY,  vorticityZ, inverseAdmittanceSquared, -vorticityX],
  [ velocityZ, -vorticityY,  vorticityX, inverseAdmittanceSquared]
]
```

This uses ordinary field reassociation of the source's `alpha * (velocity / c)`
and `alpha * (time * vorticity)`. Those correspondences are documented; a general
machine-checked rational-field proof of reassociation is not supplied here.
Scalar operations come from the existing package, not a new arithmetic system.

| Source symbol | Bend parameter | Interpretation taken from this matrix |
| --- | --- | --- |
| alpha_s | scalar_admittance | dimensionless scalar |
| alpha | shear_coupling | dimensionless coupling |
| c | phase_speed | velocity scale, nonzero |
| t_p | relaxation_time | time scale |
| v_perp | transverse_velocity | three velocity components |
| Omega | internal_vorticity | three vorticity components |

`from_parameters` returns `None` when admittance or phase speed is zero.
Otherwise it returns `Some{matrix}`. It does not enforce positive phase speed,
admittance bounds, units, or the paper's other proposed physical conditions.
These quantities are coordinate components; the code does not establish
covariance, a connection, or a nondegenerate geometric metric.

The lower-level `Coefficients` constructor deliberately accepts independent
entries: it does not certify that the diagonal coefficients are reciprocals.
Use `from_parameters` to calculate that relationship; direct `assemble` is only
the matrix-layout operation.

## Files and dependency reuse

- `Coefficients.bend`: parameters and rational coefficient calculation; independent
  divisions and component multiplications use parallel calls.
- `Matrix4.bend`: small scalar-generic fixed-shape matrix, transpose, pointwise zip,
  and map. It has exactly four rows/columns by construction, not list length claims.
  It is a candidate for extraction into a reusable package, not yet published.
- `Tensor.bend`: direct assembly, symmetric diagonal sector, antisymmetric sector.
- `Fixtures.bend`: canonical rational sample inputs and independent expected entries.
- `LAWS.bend` / `PROOF.bend`: three universal structural claims and six concrete
  regression claims, with their proofs.
- `Demo.bend`: readable rational output.
- `Tensor.lean`: supporting field-generic mathlib reference; NOT TYPECHECKED.
- `GAPS.md`: what was actually found in the ecosystem and what is still needed.

Actual resolved imports:

| Package | Used for | Locally resolved hash |
| --- | --- | --- |
| `bend-kit-bignum@0.1.0.0/rational.bend` and `bigint.bend` | Exact signed rational arithmetic, normalization, division failure | `0xbf5d8bf07d7411858acb5142889fc4d7` |
| `bend-mathlib@0.7.2.0/equal.bend` | `cong2` proves that pointwise matrix operations preserve supplied equalities | `0x449abff091641d732d7b9f0780df40ae` |

The imported rational type exposes its raw constructor. Normalized, nonzero-
denominator inputs are an API precondition, not a predicate proved by this code.
Use `Rational.make` or `Rational.read` in callers. Fixture literals deliberately
spell canonical expected values independently of the implementation under test.

## Exactly what checked

On Bend 2.0.35:

- `Demo.bend` ran and printed the exact fractions above.
- `PROOF.bend --check-only` and `PROOF.bend` reported `ALL PROOFS CHECK`.
- Universal: transpose twice returns the original matrix for every scalar type;
  pointwise operations preserve equal inputs; the constructed diagonal sector
  is symmetric for every coefficient record.
- Concrete fixture only: parameter-to-coefficient calculation, all 16 matrix
  entries, sector sum, antisymmetry, and the two zero-denominator failures.
- Mutation test in a scratch copy: flipping the `(x,y)` vorticity sign caused
  `Laws.fixture_matrix` to fail. The real source was left unchanged.

`bend PROOF.bend --verdict` was attempted but could not build the proven kernel:
it requires Lean v4.34.0 or a prebuilt `$BENDTT`, neither available here.
**Ordinary checker acceptance is recorded; kernel rechecking is NOT recorded.**

General rational-field laws, general sector-decomposition/antisymmetry proofs,
real-number coverage, and physical validity are not implied by these results.
