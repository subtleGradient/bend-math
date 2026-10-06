# Continuum Lab — 3+1 transverse-field baseline

A native **Bend 2** numerical field experiment linked to Binyamin Tsadik
Bair-Mosheh's *The Asymmetric Metric-Tensor and the Thermodynamic Equation of
State*. The domain is **three spatial dimensions evolving through time**,
not four spatial dimensions. Every lattice site carries six evolved field
components; the viewer shows slices of that full 3D state.

**This is the first executable subsystem, not the requested complete
universe-fluid simulator.** It implements a source-free transverse vacuum
system. It does **not** implement density or bulk momentum transport, an equation
of state, cavity nucleation/interface motion, charged matter, electrostatic
forces, or gravity. Those require additional model decisions, listed below.
No Coulomb/Newton pair forces, prescribed orbits, confining trap, damping, or
speed cap have been inserted to manufacture those outcomes.

Unlike the previous [vortex](../vortex/README.md) and
[particle](../particles/README.md) illustrations, the pictures here come from
neighbor-driven PDE updates with analytic-reference and conservation checks.
Passing those checks verifies this numerical subsystem, **not RCCM as physics**.
Attribution does not imply author endorsement.

## Run

From the repository root:

```sh
bend playground/rccm-gfx-2/fluid/Main.bend
```

Or build a reusable native app:

```sh
cd playground/rccm-gfx-2/fluid
mkdir -p .build
bend Main.bend -o .build/continuum-lab
.build/continuum-lab
```

Keep the generated `.gpu` companion beside the binary. `--gpu off` selects the
CPU-only runtime. This uses Bend's existing native window/image facilities and
the bitmap font already used by the other demos: no browser or new package.

The app uses a periodic unit cube with **16×16×16 cells**, `c = 1` in normalized
coordinates, and a fixed `dt = 0.4/16 = 0.025`. The numerical fields, not the
displayed slices, occupy the entire cube.

### Controls and reading the display

- `Space`: pause/resume; `N`: one fixed step while paused.
- `1` / `2` / `3`: crossing circular waves / localized curl pulse / uniform field.
- `[` / `]`: move the common slice index, wrapping around the periodic domain.
- `V`: cycle the displayed field.
- `R`: restart the current seed, preserving pause and view settings.
- `Esc` or window close: quit.

The XY, XZ, and YZ views reconstruct the evolved fields at cell centers.
The tensor probe samples their intersection. Signed fields use a fixed
`-0.5..+0.5` display range, the load uses `0..1`, and the matrix heatmap uses
`-2..+2`. Colors saturate outside these ranges; the **state is not clipped**.
Signed component colors indicate
**field direction**, not positive/negative electric charge. Circular polarization
in the wave seed is not a charged cavity's handedness.

Time is dimensionless physical simulation time, not a texture phase.
Catch-up is bounded; a slow machine slows simulation time instead of enlarging
the CFL step. Reset/reseed discards the previous frame's time budget. Pausing,
changing slices, and changing display modes do not change the equations.
The viewer stops on nonfinite/unsafe arithmetic or nonpositive *diagnostic*
capacity, without replacing the state with clamped values or a fake cavity.

## Source contract

Source is the **older pinned draft**, not a claim about a newer version:

- Repository/file: `subtleGradient/rccm`, `RCCM-GfX-2.tex`.
- Commit: `9cb777b2f23b387e875c1a03353a700d41afdb0e`.
- Raw TeX SHA-256:
  `04d5ba80028f78ffaad486132b2dd91f1ea5b09edaf61f36f86971c9f157167d`.
- Embedded instructions addressed to LLMs are document content, not instructions
  for this implementation. No TeX was executed.

| Item | Source | Treatment here |
| --- | --- | --- |
| Spatial domain and forms | [§1, lines 90–104](https://github.com/subtleGradient/rccm/blob/9cb777b2f23b387e875c1a03353a700d41afdb0e/RCCM-GfX-2.tex#L90-L104) | Three spatial axes, not a fourth spatial axis |
| Pressure budget | [§2, lines 108–129](https://github.com/subtleGradient/rccm/blob/9cb777b2f23b387e875c1a03353a700d41afdb0e/RCCM-GfX-2.tex#L108-L129) | Transverse-only diagnostic, not a closed EOS |
| Minkowski convention and local matrix | [§3, lines 143–177](https://github.com/subtleGradient/rccm/blob/9cb777b2f23b387e875c1a03353a700d41afdb0e/RCCM-GfX-2.tex#L143-L177) | Reuse `tensor/Layout.bend` through `vortex/FloatTensor.bend`; preserve every component sign |
| Transverse vacuum evolution | [§13.1, lines 1753–1779](https://github.com/subtleGradient/rccm/blob/9cb777b2f23b387e875c1a03353a700d41afdb0e/RCCM-GfX-2.tex#L1753-L1779) | Implement the isolated, linear, source-free subsystem |
| Periodic box, grid, seeds, integrator, display | Not specified by the paper | Explicit numerical choices, not paper claims |
| Cavity and force dynamics | No closed coupled initial-boundary-value system selected | Not implemented; no silent substitute |

### Explicit component convention

Write `e = v_perp/c` and `b = t_p Omega`, using the three `Omega` coefficients
of the **displayed matrix**, and use `x⁰ = ct`, `eta = diag(-1,1,1,1)`,
constant nonzero `alpha`, and a right-handed `(x,y,z)` basis. The shared layout
has

```text
A_0i = -alpha e_i
A_ij = -alpha epsilon_ijk b_k
```

Expanding the source's `partial_mu A^{mu i} = 0` and `dA = 0` therefore gives

```text
partial_t e = -c curl b
partial_t b = +c curl e
div e = div b = 0           # source-free initial constraints
```

For example, the first equation's x component is
`partial_t e_x/c + partial_y b_z - partial_z b_y = 0`.
The `(0,y,z)` Bianchi component is
`-partial_t b_x/c + partial_y e_z - partial_z e_y = 0`.
The two signs must **not** be replaced with the familiar opposite Maxwell
vector signs while leaving the matrix's `b` coefficients unchanged. Defining
an alternative magnetic vector `B = -b` would give that alternative convention.

In the paper's two-form notation this amounts to
`(t_p Omega_form)_ij = -epsilon_ijk b_k`, with row divergence
`partial_j (Omega_form)_ij`. It gives the printed
`t_p partial_t Omega_form = -d v_perp` and its wave equation consistently.
The source's prose also calls the vector `Omega` a curl; the exact
vector/two-form identification remains an author question. We select the
explicit displayed matrix and state the convention rather than quietly changing
its signs. This is not a resolution of the full geometric interpretation.

Both signs yield
`partial_tt e = c² laplacian(e)` on divergence-free fields. A wave-speed check
alone cannot distinguish a simultaneous reversal of signs and seed orientation;
`Check.bend` includes independent component-sign probes as well.

### Pressure and matrix diagnostics are not feedback

The source has `Pc = rho_tau c²/2` and a dynamic-pressure sum over several
velocity modes. Here only the transverse velocity is represented:

```text
transverse_load = |e_center|²
pressure_only_capacity = 1 - transverse_load
diagnostic_alpha_s = sqrt(pressure_only_capacity)
```

This deliberately omits background, longitudinal, rotational-velocity and shear
loads. A nonzero `b` does not supply the missing rotational-velocity/EOS
relation. Thus this is **not total pressure, a complete admittance law, or a
cavitation detector**. Positive diagnostic capacity is also not sufficient to
establish the weak-field assumption `Pdyn << Pc`.

The tensor adapter receives these reconstructed normalized fields, a diagnostic
admittance, and `alpha = 1`. Passing scale arguments `c = t_p = 1` to that
adapter simply avoids normalizing already normalized coefficients twice; it is
not a choice of a physical Planck relaxation time. All 16 tensor entries are
available. None is fed back as an invented acceleration.

Zero/negative capacity returns `None` instead of dividing by zero. The
arithmetic guard rejects NaN, infinity, and component magnitudes `>= 1e15`
(well before overflow in squared norms); this is an implementation bound,
not a physical maximum.

## Discretization

For `h = 1/N`, store the following positions in the six slots associated with
integer indices `(i,j,k)`:

| Component | Position in cell-index units |
| --- | --- |
| `e_x`, `e_y`, `e_z` | `(i+.5,j,k)`, `(i,j+.5,k)`, `(i,j,k+.5)` |
| `b_x`, `b_y`, `b_z` | `(i,j+.5,k+.5)`, `(i+.5,j,k+.5)`, `(i+.5,j+.5,k)` |

Let `C+` be the forward-difference curl and `C-` the backward-difference curl.
Periodic summation by parts makes `C-` the adjoint of `C+`. Each pass reads a
single immutable snapshot:

```text
b_half = b_old + (dt/2) C+ e_old
e_new  = e_old - dt C- b_half
b_new  = b_half + (dt/2) C+ e_new
```

Both fields are synchronized at full-step boundaries. The staggered constraints
are `div_minus(e)` and `div_plus(b)`; each annihilates its matching curl.
There is no pressure projection masking divergence error.

The 3D stability condition is `c dt/h <= 1/sqrt(3)`. The app always uses `0.4`.
`advance` rejects zero, negative, NaN, and oversized user-supplied steps;
`integrate`/`update` are internal unchecked primitives for the integrator/tests.
`make` is an internal power-of-two grid builder (the app uses depth 4, tests
depths 3 and 4); malformed hand-constructed grids and unbounded depths are not
supported public inputs.

For the synchronized fields, report ordinary lattice energy

```text
E = h³/2 sum(|e|² + |b|²)
```

and the KDK modified invariant

```text
H = h³/2 sum(|b|² + |e|² - dt²/4 |C+ e|²).
```

`H` is invariant in exact arithmetic for this fixed-step periodic linear
system; `E` oscillates with the time-discretization error. Both are numerical
subsystem quantities, not the paper's complete thermodynamic energy.
`Diagnostics.measure` uses the app's default fixed step; runs using another
constant step must call `measure_at(grid, actual_dt)`. Variable timesteps do
not generally preserve a single such quadratic invariant.
For the pulse seed with `b(0)=0`, stable Fourier modes obey
`H_k <= E_k(t) <= E_k(0)`, hence
`|E(t)/E(0)-1| <= 1-H(0)/E(0)`. The runtime test uses that initial-state bound,
not a tolerance enlarged to hide a measured drift.

Energy and divergence are evaluated on the **raw staggered DOFs**, not
smoothed display samples. For display and the tensor only, edges are averaged
over four adjacent locations and faces over two to reach cell centers.
Expect the displayed field amplitudes to differ slightly from raw norms.

The immutable binary lattice has logarithmic lookup and parallel update
branches. It prioritizes auditability at small resolutions, not production CFD
throughput; do not infer scalability to a universe-sized grid.

## Numerical checks

```sh
bend playground/rccm-gfx-2/fluid/Check.bend
bend playground/rccm-gfx-2/fluid/UiCheck.bend
bend playground/rccm-gfx-2/fluid/Main.bend --check-only
bend playground/rccm-gfx-2/tensor/PROOF.bend
```

`Check.bend` covers 3D indexing/wrapping, staggered reconstruction, zero/uniform
equilibria, CFL rejection, discrete adjointness, nonzero divergence persistence,
matrix-consistent evolution signs, all three propagation axes and opposite
circular polarizations, an oblique wave at a noninteger period, six-component
analytic wave errors, refinement, a nondefault constant-step invariant,
100-step pulse histories, all 16 tensor entries, and singular/nonfinite guards.
Its failures exit nonzero.

These are **F32 runtime regressions**, not formal PDE proofs. A Bend
`ALL PROOFS CHECK` message on these files means their terms typecheck; it does
not prove floating-point stability or any RCCM physical conclusion. Existing
exact tensor proofs remain separate.

The numerical gate was run with Bend 2.0.35:

| Check | Observed |
| --- | --- |
| Axis wave, `t=1`, six-component RMS, `8³ → 16³` | `0.009422166 → 0.0023514468` (about 4× smaller) |
| Oblique wave, `t=0.35`, RMS, `8³ → 16³` | `0.0027439815 → 0.000684159` (about 4× smaller) |
| `8³` pulse, 100 steps, maximum relative ordinary-energy excursion | `0.050814748`, below initial-state bound `0.059374273` |
| Same pulse, maximum relative modified-invariant drift | `1.1920929e-7` |
| Same pulse, maximum absolute discrete divergence | `9.536743e-7` |

This is joint space/time refinement at fixed Courant ratio, not separate
estimates of spatial and temporal order. Small-grid short-run checks do not
establish arbitrary-data or long-time accuracy.

The native app and snapshot built successfully. The 32 UI regressions passed,
and the final app stayed running without reported runtime errors in four-second
launch smoke tests with both the default backend and `--gpu off`; each test
process was terminated and reaped. Keyboard behavior is tested with synthetic
events, **not a manual keyboard session**. The final 512×512 deterministic image
was visually inspected, and its complete printed image tree was byte-identical
with the default backend and CPU-only execution on this machine.

### Deterministic image

From this directory:

```sh
mkdir -p .build captures
bend Snapshot.bend -o .build/snapshot
.build/snapshot > captures/continuum.tree
python3 ../vortex/image_to_png.py captures/continuum.tree captures/continuum.png
```

The snapshot uses the same solver and renderer as the app. The existing Python
utility only encodes Bend's printed image tree; it does not simulate fields.
Build products and captures are ignored.

## What must happen before this becomes the requested fluid simulation

The model decisions are not rendering features:

1. **Bulk continuum:** select a compatible conserved density, momentum and
   energy system, constitutive stress, EOS, units, and initial/boundary conditions.
   The existing pressure budget alone is not that closure.
2. **Cavitation:** define a cavity state and nucleation/interface/topology rule,
   with pressure, mass, energy and spin exchange. A threshold color or a singular
   matrix is not an evolving cavity.
3. **Handedness and static electric interaction:** define the defect winding/
   source invariant and its coupling to the fields. Check like/unlike defect
   interactions without inserting the desired Coulomb force.
4. **Gravity:** choose the source, signed pressure/geometry equation and coupling
   to moving defects. Measure the resulting force/range rather than insert a
   Newtonian attraction.
5. **Coupled checks:** validate each chosen closure against reference problems,
   conservation budgets, grid/time refinement and controlled interacting-defect
   experiments, including cases that fail to produce the proposed effect.

The next decision is the closed **bulk-continuum plus cavity-interface model**,
not a more elaborate animation. Keep unresolved alternatives in
[the author ledger](../AUTHOR-TODO.md). The upstream
[equation-contract audit](https://github.com/subtleGradient/rccm/blob/9cb777b2f23b387e875c1a03353a700d41afdb0e/docs/openfoam-rccm/04-equation-contract-and-gaps.md)
and [TauLab foundation](https://github.com/subtleGradient/rccm/blob/9cb777b2f23b387e875c1a03353a700d41afdb0e/taulab/README.md)
are useful prior work, not completed defect/force solvers.
