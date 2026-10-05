# Bernoulli: vortex-context starter fixture

This is a teaching/test fixture, not a transcription of a supplied paper.
No friend's PDF or TeX has been provided. Do not invent source locators.

This was the initial blocked prototype, not the expected final Bend-first
output. Its unchecked Lean slice is retained as a supporting reference. No Bend
implementation is claimed here; the old blocker records an unverified candidate,
not proof that exact numeric libraries are absent. A new run must inspect
supported packages and deliver a useful generic/scoped Bend component where
possible, with a gap ledger, rather than repeat the blanket blocked outcome.

## Scope

Start with the pressure-form expression:

```latex
p + \frac{1}{2}\rho v^2 + \rho g z = C
```

Copyable descriptive reading:

```text
pressure
+ density * speed * speed / 2
+ density * gravitationalAcceleration * elevation
= bernoulliConstant
```

The conventional steady, constant-density, inviscid model under uniform gravity
conserves this quantity along a streamline. Constancy across different streamlines
does not follow in general. Irrotationality is a familiar additional sufficient
condition in the usual connected smooth-flow setting, not an assumption to insert
silently when discussing vortices.

References: [OpenStax, section 14.6](https://openstax.org/books/university-physics-volume-1/pages/14-6-bernoullis-equation)
for the pressure form; [UT Austin's Bernoulli laboratory](https://caee.webhost.utexas.edu/prof/kinnas/319LAB/Lab/lab%204-Bernoulli%27s%20equation/4-Bernoulli.htm)
for the along-streamline versus irrotational-region distinction.
These are background sources for this constructed fixture, not the user's paper.

This equation alone is not a model of a tornado or a vortex ring. A ring (toroidal
vortex, like a smoke ring) and a tornado-like column are different configurations.
Do not assume steady flow, incompressibility, or negligible viscosity applies to
the user's intended phenomenon just because Bernoulli is the starting point.

## Minimal semantic slice

The asset [Bernoulli.lean](../assets/Bernoulli.lean) defines a scalar expression and
the displayed equality to `bernoulliConstant` using mathlib's `Real`.
`BernoulliAt` takes the six quantities as parameters: it neither chooses a
constant nor asserts that one constant works along a streamline or across a flow.
It does NOT encode a velocity field, streamline membership, the Euler equations,
or their consequences. Quantifier scope for a conservation claim is blocked on
`SEM-004d`; no pairwise-equality replacement or elimination of `C` is made.

**Lean checking: NOT RUN.** Lean and mathlib were not installed/pinned for this
fixture. No statement here should be read as an observed typechecking result.

| Symbol | Identifier | Intended quantity | SI unit |
| --- | --- | --- | --- |
| p | pressure | pressure | Pa |
| rho | density | constant mass density | kg/m^3 |
| v | speed | magnitude of velocity, not velocity vector | m/s |
| g | gravitationalAcceleration | magnitude of uniform gravitational acceleration | m/s^2 |
| z | elevation | vertical coordinate increasing upward | m |
| C | bernoulliConstant | streamline-specific constant in this model | Pa |

The Lean scalar encoding does not enforce these units or physical sign constraints.
It is an explicit first slice, not the complete semantics of fluid mechanics.

## Author-facing ledger

All locators below refer to this constructed fixture, not an absent paper.
No resolution evidence exists yet. `SEM-004` is the parent of four smaller gaps.

| ID | Kind / locator | Precise question | Affected declaration | Alternatives | Owner | Status |
| --- | --- | --- | --- | --- | --- | --- |
| TODO[SEM-001] | Source; Scope | Which actual equation and definitions should be transcribed? | All eventual paper declarations | Await paper or retain constructed fixture | Author | Open; fixture only |
| TODO[SEM-002] | Interpretation; Scope | Which vortex geometry and reference frame are intended, and is flow steady in it? | Future flow model | Ring / column / other; laboratory / co-moving frame | Author | Open |
| TODO[SEM-003] | Interpretation; Scope | Which premises does the author actually assert? | Future conservation claim | Steady / unsteady; constant / variable density; inviscid / viscous | Author | Open |
| TODO[SEM-004a] | Representation; Symbols | Which unit convention or quantity types should encode dimensions? | bernoulliPressure, BernoulliAt | Explicit SI magnitudes / dimension-checked quantities | Author and translator | Open; units currently external |
| TODO[SEM-004b] | Representation; Symbols | Which sign/domain restrictions are required for physical quantities? | Future admissibility predicate | Explicit scalar predicates / constrained quantity types | Author and translator | Open; current Real parameters unrestricted |
| TODO[SEM-004c] | Representation; Minimal semantic slice | What spatial/time domain and fields represent the flow? | Future flow model | Steady spatial fields / time-dependent fields | Author and translator | Blocked on SEM-002 and SEM-003 |
| TODO[SEM-004d] | Interpretation; Scope and C in Symbols | Is C chosen per streamline or asserted common across a region, and why? | Future quantified conservation claim | Per-streamline existential / one common constant with extra premises | Author | Open; BernoulliAt asserts neither |
| TODO[SEM-005] | Target-library gap; Minimal semantic slice | Which available Bend representation faithfully supports the intended real-valued domain? | Bend counterparts of bernoulliPressure and BernoulliAt | Verified library / explicit future abstraction; F32 only as separate approximation | Translator | Blocked; no candidate verified |
| TODO[SEM-006] | Future proof handoff; Scope | Once meanings are fixed, does the conservation claim follow from the chosen governing assumptions? | Future conservation theorem | Proof workflow after semantic review | Proof workflow owner, after author review | Blocked on SEM-002, SEM-003, SEM-004; not proof-pending |

## Target mapping

| Slice | Target | Declaration | Fidelity | Availability | Check status |
| --- | --- | --- | --- | --- | --- |
| Scalar left-hand expression | Lean | bernoulliPressure | Exact Real algebra; units external | Present | Not run |
| Displayed scalar equality to C | Lean | BernoulliAt | Exact parameterized equality; no conservation quantifiers | Present | Not run |
| Quantified physical conservation | Lean | None | Unresolved | Blocked on SEM-002 through SEM-004 | Not run |
| Exact scalar equation | Bend | None | Unresolved target encoding | Blocked on SEM-005 | Not run |

## Initial gap evidence and next action

| Gap ID | Required operation and law | Searched package/version evidence | Current workaround / dependency | Minimal proposed upstream API | Acceptance criterion |
| --- | --- | --- | --- | --- | --- |
| SEM-005 | Exact scalar addition, multiplication, division by two, equality; declared carrier's algebraic laws and compatibility with intended Real interpretation | Bootstrap consulted mutable bend-mathlib documentation only, not a pinned package/API or check; broader package catalog inspection not performed in this fixture | Unchecked Lean Real reference; Bend component and concrete carrier not yet supplied | Proposal only, after inspecting existing APIs: carrier-parameterized pressure expression/equality with explicit operations, lawful dependencies, and interpretation obligations | Useful component checks on pinned Bend 2; declared laws and exact-domain interpretation reviewed separately; no rational/decimal/F32-to-Real equivalence silently asserted |

This ledger describes incomplete historical evidence, not a completed ecosystem
survey. TypeScript is no longer emitted by default. An explicitly requested
numeric companion would be a separate approximate model with separate validation.
