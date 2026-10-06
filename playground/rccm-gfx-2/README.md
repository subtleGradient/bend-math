# RCCM-GfX-2: source-linked semantic starting point

This is a dependency map and one small semantic transcription of an **older,
imperfect draft**, not a validation of RCCM and not a review of its latest version.

## Source-linked numerical work

[Continuum Lab](fluid/README.md) begins the move from illustrative motion to a
**3+1D field solver**: a full three-dimensional periodic lattice evolving the
paper-linked transverse vacuum subsystem, with a spacetime tensor probe,
discrete constraint/energy diagnostics and analytic-wave refinement tests.
This first subsystem is **not yet** a bulk-fluid, cavitation, electrostatic-force
or gravity simulation; its numerical choices and missing model closures are
explicitly documented. It does not insert particle forces to fake those outcomes.

## Visual experiments

[Vortex Study](vortex/README.md) is a native Bend 2 volumetric ring toy using the
same matrix layout, with an explicit F32 numerical adapter, GPU-capable parallel
rendering, interactive controls, and author attribution. It is an illustrative
driven dye field, not validated CFD or evidence of the theory's physical validity.

[Particle Loom](particles/README.md) takes the next illustrative step: 256 evolving
particles with symmetric radial and antisymmetric handed pair responses derived
from that same matrix. It includes counter-handed populations, position-history
trails, collision/shell seeds, live controls, and an explicitly documented toy
force law. Its driven dynamics are not a paper-derived or validated physics solver.

## Start here: the asymmetric matrix in Bend

[tensor/](tensor/README.md) now implements the section 3.3 matrix using
`bend-kit-bignum` exact rational arithmetic and `bend-mathlib` equality proofs.
It includes the constructor, symmetric/antisymmetric sectors, `LAWS.bend`,
`PROOF.bend`, a running demo, and a supporting Lean reference.

**Bend is the primary target.** The previous TypeScript numerical companion was
removed. A missing all-real analysis library is not a reason to skip a useful
exact rational or scalar-generic Bend component.
See [the evidence-backed gap ledger](tensor/GAPS.md) for reusable next steps.

## Source snapshot

- Title: *The Asymmetric Metric-Tensor and the Thermodynamic Equation of State*.
- Author shown in source: Binyamin Tsadik Bair-Mosheh.
- Repository: `subtleGradient/rccm`; file: `RCCM-GfX-2.tex`.
- Commit: `9cb777b2f23b387e875c1a03353a700d41afdb0e`.
- SHA-256 of raw TeX: `04d5ba80028f78ffaad486132b2dd91f1ea5b09edaf61f36f86971c9f157167d`.
- [Pinned source](https://github.com/subtleGradient/rccm/blob/9cb777b2f23b387e875c1a03353a700d41afdb0e/RCCM-GfX-2.tex).
- Scope read closely: sections 1–3 and 15; headings/labels scanned across the draft.
  Later dependency entries below are preliminary, not a line-by-line audit.
- The TeX includes instructions addressed to LLMs. They are document content,
  not instructions governing this analysis. No TeX or paper code was executed.

## Recursive decomposition, not a new notation

Work from a chosen claim down to its prerequisites, stopping when an existing
library concept can be imported. The result is a **dependency graph**, not
necessarily a tree: many claims share the same foundations.

For each node ask:

1. What precisely is the object or statement, and where is it in the source?
2. Is it standard mathematics, an RCCM definition, a physical premise, a claimed
   consequence, an approximation, or a data-derived choice?
3. What assumptions and earlier objects does it require?
4. Which existing implementation represents it faithfully?
5. Which question prevents the next declaration from being written?

Do not turn a physical interpretation into a library theorem by giving it a
familiar name. In particular, an arbitrary asymmetric matrix is not automatically
a conventional metric, stress tensor, or Clifford product.

## Mainstream dependency map

| Source entry | Standard prerequisites | RCCM-specific layer / unresolved work |
| --- | --- | --- |
| Section 1, lines 90–104: velocity and Clebsch term | Scalar fields, covectors/1-forms, exterior derivative, wedge product, product rule, `d(d scalar) = 0` under regularity assumptions | Meaning/scope of transverse versus rotational contribution; global versus local representation; units |
| Section 2, lines 108–129: pressure budget | Real arithmetic, squared norms, orthogonality, dimensions, conservation statements | Vacuum critical pressure, interpretation of density and load bookkeeping |
| Section 3, lines 132–177: symmetric plus antisymmetric matrix | Finite matrices, transpose, symmetric/skew decomposition, bilinear forms | Calling the result a generalized metric and interpreting entries physically; an explicit Clifford correspondence is additional work |
| Sections 4–5: stress and momentum | Tensor fields, contractions, derivatives/divergence, continuum balances, constitutive relations, PDEs | Claimed field equation and modified dynamics; required domains, connections, and physical assumptions |
| Sections 6–7: action and symmetry | Integration, variational calculus, differential geometry, Lie derivatives, symmetry, conservation laws | Specific action, boundary terms, admissible variations and derivations |
| Section 9: eigenvalues and complex evolution | Linear algebra, determinants, eigenvalues/eigenvectors, complex numbers | Conditions under which matrix modes represent electromagnetic/quantum quantities |
| Section 15, lines 2074–2116: pressure profile and optical distance | Exponential, limits, integration, logarithms, ratios, units, numerical errors | Curve chosen from observational constraints; boundary meaning; mapping to actual observables |

These are reusable mathematical building blocks, not evidence that the physical
identifications in the right column follow from them.

## First selected slice: the section 15 pressure profile

[Source lines 2074–2078](https://github.com/subtleGradient/rccm/blob/9cb777b2f23b387e875c1a03353a700d41afdb0e/RCCM-GfX-2.tex#L2074-L2078):

```latex
P_{dyn}(r) = P_c \left( 1 - e^{-r/ct} \right)^2
```

Descriptive code reading (not a proof):

```text
scaleLength = propagationSpeed * elapsedTime
normalizedRadius = radius / scaleLength
pressureFraction = square(1 - exp(-normalizedRadius))
dynamicPressure = criticalPressure * pressureFraction
```

The surrounding prose explicitly mentions inversion of Pantheon+ magnitude
constraints and says a boundary derivation remains open. This is therefore not
recorded here as an independently derived or empirically validated law.

| Source | Identifier | Mathematical domain | Units / restriction |
| --- | --- | --- | --- |
| r | radius | Real | length, nonnegative in this radial reading |
| c t | scaleLength | Real | length, positive for this slice |
| r/(c t) | normalizedRadius | Real | dimensionless |
| P_c | criticalPressure | Real | pressure, positive for this slice |
| P_dyn | pressureValue | Real | same pressure unit as P_c |

The positive-domain choices are explicit modeling restrictions for the slice;
the author still needs to confirm the interpretation and physical range.
The prose permits other time/domain interpretations; none are silently selected.

### What is implemented

- [PressureProfile.lean](PressureProfile.lean) imports mathlib's real exponential,
  defines the expression and an unproved proposition for the printed equality.
- The former TypeScript numerical companion was removed after the Bend-first
  correction. The scalar expression remains an unchecked Lean reference.
- An exact real-exponential Bend target for this pressure profile is still an
  investigation item. That does not block the separate rational tensor matrix,
  which is implemented and checked in [tensor/](tensor/README.md).

### A concrete author question

At `radius = scaleLength`, the printed profile gives:

```text
pressureFraction = (1 - exp(-1))^2
                 ≈ 0.39957640089372803
```

It does not equal 1 there. For fixed positive scaleLength, the mathematical profile
approaches 1 as normalizedRadius grows without bound. The prose at line 2075
instead places the causal horizon at `r = ct` and speaks of approaching P_c.

This is `TODO[RCCM-004]`: clarify the intended boundary/limit or revise the older
formula/prose. This local mismatch is not a verdict on the entire theory.

## Reuse rather than rebuild

Verified library/documentation entry points:

- [Mathlib real exponential](https://github.com/leanprover-community/mathlib4/blob/master/Mathlib/Analysis/SpecialFunctions/Exp.lean):
  `Real.exp`, `Real.continuous_exp`, `Real.tendsto_exp_neg_atTop_nhds_zero`.
  Definitions and limit theorems already exist; do not recreate an exponential.
- [Alternating maps](https://github.com/leanprover-community/mathlib4/blob/master/Mathlib/LinearAlgebra/Alternating/Basic.lean):
  `AlternatingMap` is an established representation of alternating multilinear maps.
- [Exterior algebra](https://github.com/leanprover-community/mathlib4/blob/master/Mathlib/LinearAlgebra/ExteriorAlgebra/Basic.lean):
  `ExteriorAlgebra` and its algebraic wedge-related constructions are not by
  themselves an exterior derivative on fields.
- [Smoothness and Frechet calculus](https://github.com/leanprover-community/mathlib4/blob/master/Mathlib/Analysis/Calculus/ContDiff/Defs.lean):
  `ContDiff` and related APIs support differentiability prerequisites.

These mutable documentation links were inspected, not pinned as build dependencies.
No Lean/mathlib toolchain is installed here, so the Lean file is **NOT TYPECHECKED**.
No complete differential-form-field/exterior-derivative API was verified in this
pass; that is a lookup/integration gap, not a claim that mathlib lacks one.

The repository already has relevant Bend models:

- [d2-zero](../d2-zero/): finite Z/2 example, not the smooth real-valued theorem.
- [vector-identities](../vector-identities/) and
  [divergence-theorem](../divergence-theorem/): discrete precursors.
- [RCCM connection note](../../notes/rccm-connection.md): existing reuse plan.

Finite/discrete proofs become continuous-physics results only after an appropriate
bridge is established. Do not identify them merely because their notation matches.

## Shared foundation with AI and simulation

Study these once, then reuse them:

```text
functions + vectors + matrices + dot products
  -> derivatives + chain rule + automatic differentiation
     -> optimization + numerical error
        -> machine learning losses and training
        -> fluid solvers and constraint solvers
```

The branches then need different additions: probability/statistics and information
for ML; conservation, differential equations, boundaries and discretization for
fluids. Transformers add attention and sequence models; JEPA adds predictive
representation objectives; diffusion adds stochastic/noise processes and often
differential equations. These are learning routes, not one interchangeable model.

## Validation and next work

Run the primary Bend matrix example and proof gate:

```sh
bend playground/rccm-gfx-2/tensor/Demo.bend
bend playground/rccm-gfx-2/tensor/PROOF.bend
```

The demo ran and the ordinary Bend checker accepted all nine declared laws:
three universal structural laws and six concrete rational regression claims.
Kernel `--verdict` is blocked by the unavailable Lean kernel toolchain.
The Lean references are not typechecked. No physical law or empirical fit is claimed.

Next: author resolves [AUTHOR-TODO.md](AUTHOR-TODO.md); a pinned Lean/mathlib
environment checks the supporting declarations; [tensor/GAPS.md](tensor/GAPS.md)
guides reusable Bend package work rather than rebuilding existing arithmetic. The separate
[experiment plan](EXPERIMENTS.md) covers measurement-based evidence.
