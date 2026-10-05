# Particle Loom

A native **Bend 2** particle-interaction playground inspired by Binyamin Tsadik
Bair-Mosheh's **Asymmetric Metric-Tensor**. Two luminous, counter-handed
populations gather, repel, collide, and wind into overlapping coils. The trails
are recorded particle positions, not an animated texture or prescribed orbit.

**This is an illustrative, driven toy—not validated RCCM physics.** The matrix
layout comes from the paper; the particle force law, handed populations, trap,
damping, seeds, and rendering are our choices. The credit identifies the
inspiration, not author endorsement.

## Run

From the repository root:

```sh
bend playground/rccm-gfx-2/particles/Main.bend
```

Or build a reusable native app:

```sh
cd playground/rccm-gfx-2/particles
mkdir -p .build
bend Main.bend -o .build/particle-loom
.build/particle-loom
```

The app displays a 512x512 internal image in a 1024x1024 native window. Matching
Bend's power-of-two image square avoids cropping the HUD. Keep the generated
`.gpu` file beside the binary. Bend's supported GPU backend is on by default;
use `.build/particle-loom --gpu off` for CPU-only execution.

This uses the same native window dependencies as [Vortex Study](../vortex/README.md).
There is no browser, JavaScript runtime, external renderer, shader companion,
or new package dependency.

## First things to try

1. Let the default **Braid** seed develop for a few seconds.
2. Press `O` to hold the camera still and watch the two populations' trails.
3. Press `1`: the skew drive disappears, but particles still have inertia,
   radial interactions, confinement, and damping. **Symmetric is not paused.**
4. Press `2`, then `3`: the handed acceleration reverses without teleporting
   particles or erasing their history. Existing velocity takes time to turn.
5. Press `5` for two head-on clouds, or `6` for an interleaved shell.
6. Tap `B` to give the current particles an outward kick.
7. Try `A`/`D` while the camera is still to change the symmetric response.

The teal and copper colors identify opposite **toy handedness labels**, not
electric charge, actual quantum spin, or distinct materials.

## Controls

| Key | Action |
| --- | --- |
| `Q` / `E` | Decrease / increase coupling, bounded to -2..2 |
| `A` / `D` | Decrease / increase admittance, bounded to 0.55..1 |
| `1` | Symmetric only: coupling 0 |
| `2` | Coupled: coupling +1 |
| `3` | Reversed: coupling -1 |
| `4` / `5` / `6` | Reseed Braid / Collision / Shell, keeping current coefficients and view settings |
| `B` | Outward velocity burst; no particles are created |
| `Space` | Pause particles, history, and camera |
| `O` | Toggle camera orbit |
| `T` | Show / hide trails without changing dynamics or stored history |
| `R` | Reset particles, coefficients, view settings, and simulation clock |
| `Esc` / window close | Quit |

Coefficient keys support auto-repeat. Toggles, bursts, and resets are
press-edge actions: holding a key does not repeatedly toggle or restart.
Uppercase aliases work. Reset and reseed discard the previous frame's elapsed
time so the initial state is actually shown.

## Precisely where RCCM enters

The existing [F32 adapter](../vortex/FloatTensor.bend) calls the same
[component layout](../tensor/Layout.bend) as the
[exact rational tensor](../tensor/README.md). We reuse it without copying or
changing its signs.

For this illustration we choose, in dimensionless toy units:

```text
v_perp = (0, 0, 0)
c = 1
t_p = 1
Omega = (0.25, 0.35, 1)
alpha_s = admittance
alpha = coupling
```

The nonzero tilted axis is an illustrative choice, not a vorticity field
calculated from the particles. Setting `v_perp = 0` means this demo does **not**
exercise the time-space velocity sector or the time row.

The spatial block then splits into:

```text
S r = alpha_s^-2 r
A r = alpha t_p (Omega cross r)
```

`Simulation.response` builds the actual matrix and probes its x/y spatial basis
vectors once per batch of integration steps. This caches its diagonal and three
skew coefficients; `Simulation.symmetric` and `Simulation.skew` apply that
linear map in the pair loop. A numerical regression compares the cached map to
direct matrix multiplication, including the cross-product sign.

### The invented particle closure

Each of 256 equal-weight particles has position `x_i`, velocity `v_i`, and fixed
handedness `s_i` equal to +1 or -1. All interactions in a step read the same old
position snapshot; no particle observes another particle's partially updated
position.

For the response on particle `i` due to particle `j`:

```text
r = x_j - x_i
d = length(r)
q = (s_i + s_j) / 2
w = max(0, 1 - d / 1.65)^2
h = 0.22 + 0.78 abs(q) - 0.12 / (d^2 + 0.0081)

F_ij = (12 / 256) w [h S r + 1.8 q A r]
```

- At short distance the softened radial channel repels; farther out it attracts.
  The falloff removes interactions beyond the finite cutoff.
- Same-handed pairs have `q = +1` or `q = -1`: opposite circulating drives.
  Mixed pairs have `q = 0`: weaker radial cohesion and no skew drive.
- Swapping the two particles negates `r` but preserves `q`, `h`, and `w`, so
  the pair rule is equal and opposite in exact arithmetic. F32 summation is
  approximate.
- The skew response is perpendicular to **displacement**, not necessarily to
  velocity. It can drive motion and inject energy; it is not a proof of
  work-free magnetic dynamics or a conservation law.
- Coupling zero removes `A` while leaving `S`. Changing its sign reverses only
  the skew contribution, not the current state or the arrow of time.
- The soft core has no division by distance. Exactly coincident particles
  receive zero pair response, not an exact collision-resolution impulse.

The numerical integrator is semi-implicit Euler with a fixed step approximately
equal to `1/120` toy second:

```text
F_i = sum_j F_ij - (0.35 + 0.24 length(x_i)^2) x_i
v_i' = limit_speed(0.9933555 [v_i + dt F_i], 2.8)
x_i' = x_i + dt v_i'
```

The centered trap, damping, and speed cap are deliberate stabilizers. The full
system does **not** conserve momentum, angular momentum, or energy. No pressure
projection, physical units, relativistic evolution, collision solver, or
Navier–Stokes solve is claimed.

Live frames accumulate fixed steps, capped at 50 ms of catch-up per displayed
frame. A slow machine therefore slows toy time rather than taking unbounded or
unstable steps. Histories retain up to 14 positions sampled every six steps
(roughly 0.7 toy second), regardless of whether trails are visible.

## Rendering and parallel work

- A balanced tree supplies independent particle updates; each walks an immutable
  flat snapshot of the 256 positions. Interaction cost is O(N^2), intentionally
  small and easy to inspect.
- The renderer projects actual heads and historical segments into additive
  emissive strokes. Brightness is an artistic display mapping.
- Host-side bounds bin strokes into 32x32 screen cells. Four cell fork levels
  plus three tile fork levels yield 16,384 independent 4x4 render tiles with one
  GPU dispatch. A pixel sees only its tile's nearby candidates.
- The native app and deterministic snapshot use the same simulation and renderer.

## Capture a still

Run from this directory:

```sh
mkdir -p .build captures
bend Snapshot.bend -o .build/snapshot
.build/snapshot > captures/loom.tree
python3 ../vortex/image_to_png.py captures/loom.tree captures/loom.png
```

The default snapshot evolves the Braid seed for 720 fixed steps (six toy
seconds) at admittance 0.82 and coupling +1, with a stationary camera. Edit the
constants in `Snapshot.bend` for other seeds, times, and coefficients. The
existing Python utility only encodes Bend's printed `Image` as PNG; it does not
simulate or render the particles. Builds and captures are ignored.

## Checks and benchmark

From this directory:

```sh
bend Main.bend --check-only
bend Check.bend
bend ../tensor/PROOF.bend
bend ../vortex/Check.bend

bend Benchmark.bend -o .build/benchmark
.build/benchmark
.build/benchmark --gpu off
```

`Check.bend` contains 42 runtime regressions: matrix equivalence and signs,
perpendicular skew response, pair exchange, softened/cutoff behavior, actual
neighbor-driven trajectories, coefficient edits, fixed stepping, pause, native
key repeat, reset/reseed, burst, HUD/head rendering, and ten-second runs at
representative parameter extremes. F32 arithmetic is opaque to Bend's ordinary
checker; these are **numerical regressions, not formal proofs** of physics or
global stability. Existing exact tensor proofs remain separate.

The native app built and stayed running in six-second launch smoke tests with
the default backend and CPU-only execution. The deterministic still was visually
inspected. Controls are exercised by synthetic event regressions; full manual
keyboard interaction has not been tested.

The benchmark warms up at six toy seconds, then evolves four fixed steps and
renders each of 20 frames, consuming every pixel with a CPU checksum. It includes
simulation, screen binning, rendering, checksum, and cleanup—not isolated GPU
time or displayed FPS. A local sample measured 157 ms with the default backend
and 173 ms CPU-only, with matching checksums; do not generalize one run to other
machines.

## Next path toward legitimate dynamics

Keep the visual shell; replace the explicit closure in `Simulation.bend`.
Agree with the author on which source balance/field equation should govern the
particles, the meanings and units of the state variables, how local `Omega` and
`v_perp` are computed, and what boundaries and conservation claims apply. Then
add convergence, conservation, and reference-case tests for that rule before
making physical claims. Removing the speed cap is not, by itself, validation.

## Sources and files

- Binyamin Tsadik Bair-Mosheh, *The Asymmetric Metric-Tensor and the Thermodynamic
  Equation of State*, older RCCM-GfX-2 draft:
  [section 3.3, matrix lines 172–177](https://github.com/subtleGradient/rccm/blob/9cb777b2f23b387e875c1a03353a700d41afdb0e/RCCM-GfX-2.tex#L172-L177).
  Source provenance and scope are recorded in [the parent README](../README.md).
- `Simulation.bend`: cached tensor response, pair law, seeds, fixed-step dynamics.
- `Vector.bend`: small F32 vector operations.
- `Controls.bend`, `Main.bend`: state, press-edge input, timing, native app.
- `Render.bend`, `Hud.bend`: projected heads/trails, binned parallel renderer,
  controls and attribution; the HUD reuses Vortex Study's bitmap font.
- `Snapshot.bend`, `Benchmark.bend`, `Check.bend`: headless still, end-to-end
  benchmark, and numerical regressions.
