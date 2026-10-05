# Vortex Study

A native **Bend 2** visual toy inspired by Binyamin Tsadik Bair-Mosheh's
**Asymmetric Metric-Tensor**: a luminous volumetric vortex ring, with live
admittance, coupling, camera, and cutaway controls.

This is a driven procedural-dye visualization, **not a validated CFD solver or
experimental evidence for RCCM**. The flow closure, torus geometry, dye source,
and emission palette are visual choices. The source matrix is actually used,
not just attached as a label.

## Video demo

[Watch Vortex Study in action on YouTube Shorts](https://www.youtube.com/shorts/0JiEdy862ns).

## Run

From the repository root:

```sh
bend playground/rccm-gfx-2/vortex/Main.bend
```

For a reusable native binary:

```sh
cd playground/rccm-gfx-2/vortex
mkdir -p .build
bend Main.bend -o .build/vortex
.build/vortex
```

Bend's supported GPU backend is enabled by default. To use CPU parallelism:

```sh
.build/vortex --gpu off
```

The native app uses a 512x512 internal image displayed at 2x scale in a
1024x1024 window. Bend maps the image to the next power-of-two square and crops
it to the window, so the window dimensions match that square to keep the full
vortex and HUD visible.
It requires Bend's native window/build dependencies; there is no browser,
TypeScript, external render engine, or shader-language companion.

## Controls

| Key | Action |
| --- | --- |
| `Q` / `E` | Decrease / increase signed asymmetric coupling |
| `A` / `D` | Decrease / increase scalar admittance, bounded to 0.55..1 |
| `1` | Symmetric only: zero coupling |
| `2` | Full coupling: +1 |
| `3` | Reversed coupling: -1.5 |
| `C` | Cut away half the volume to inspect the tube |
| `Space` | Pause both dye animation and camera |
| `O` | Toggle camera orbit |
| `R` | Reset all controls, time, and camera |
| `Esc` / window close | Quit |

**First demonstration:** press `O` to hold the camera still, then `1` to remove
the asymmetric terms. The dye stops moving. Press `2` to restore motion, then
`3` to reverse it. `A`/`D` changes the ring's tube thickness through the symmetric
diagonal response. Material phases accumulate from the matrix-derived rates:
changing coupling changes subsequent motion without teleporting the pattern.
Only `R` resets the material phases.

Signed coupling extends beyond the paper's proposed physical interpretations.
It is an exploratory control, not a claim that every setting is physically valid.

## Where the tensor enters

The component signs and positions are shared with the exact rational code in
[`../tensor/Layout.bend`](../tensor/Layout.bend). Both backends call that layout.

1. `FloatTensor.matrix` computes the paper's coefficients in `F32`.
2. `Field.rates` applies that actual matrix to a spatial basis vector and a
   time-basis vector.
3. The probes supply a diagonal scale, a skew rotation rate, and a time-space
   drift rate. `Controls.advance` accumulates the two material phases from these
   rates and frame time; `Field.from_phases` prepares their rendering transforms.
4. In a local toroidal frame, the rotation rate advects the procedural pattern
   around the tube; the drift rate carries it around the ring. The diagonal
   response changes the tube's static compression.
5. `Render` ray-marches the resulting emissive volume.

The material-coordinate rotations are analytic, not a discretized fluid pressure
solve. We maintain a procedural dye source rather than enforcing mass conservation.
The diagonal compression is a display mapping, not a solution of the continuity
equation. There is no evolving velocity grid, pressure projection, Navier–Stokes
solve, physical unit calibration, or back-reaction in this first toy.

This is a useful visual starting point for later tracer integration or a
pressure-projected grid solver, not a substitute for those steps.

## Parallelism you can experiment with

`Render.frame` has one `!` dispatch. Seven quadtree fork levels produce
`4^7 = 16,384` independent tiles. Each tile computes a 4x4 block without more
parallel forks. Volume rays take 64 samples inside a bounding sphere; HUD pixels
skip volume work.

The frame has no mutable shared fluid grid. That deliberately keeps this first
version close to Bend's strengths: independent work, bounded ray loops, and a
small immutable per-frame state.

To benchmark default execution versus CPU-only, without opening a window:

```sh
bend Benchmark.bend -o .build/benchmark
.build/benchmark
.build/benchmark --gpu off
```

The benchmark warms up once, then renders 20 deterministic frames and consumes
every pixel with a checksum. It measures **end-to-end render + CPU checksum +
cleanup**, not isolated GPU kernel time or displayed FPS.

On the development machine, one run measured 247 ms default versus 609 ms CPU-only
for those 20 frames. These are illustrative local results, not a controlled
multi-run performance claim. CPU/default images differed by at most one RGB-byte
level in the checked snapshot, so checksums need not match across backends.

## Share a still

The snapshot uses the actual Bend renderer. The optional Python utility only
encodes its printed `Image` quadtree as PNG; it performs no flow or rendering.

```sh
mkdir -p .build captures
bend Snapshot.bend -o .build/snapshot
.build/snapshot > captures/vortex.tree
python3 image_to_png.py captures/vortex.tree captures/vortex.png
```

Edit the constants in `Snapshot.bend` for other times, camera angles, or controls.
The live app can also be screen-recorded. Generated captures/binaries are ignored.

## Checks

```sh
bend ../tensor/PROOF.bend
bend PROOF.bend
bend Check.bend
python3 -m unittest discover -s . -p 'test_*.py'
```

- The exact rational tensor's nine existing laws still pass.
- Three structural control claims pass the ordinary checker.
- Eleven native runtime regressions check matrix-driven motion, reversal,
  zero-coupling freeze, pause, safe admittance endpoints, and phase continuity.
- `F32` arithmetic is opaque to the current checker; runtime numeric checks
  are deliberately not disguised as `rfl` proofs.
- The native app built and stayed running during a bounded launch smoke test.
  Complete interactive key behavior has not been manually exercised.
- A generated headless image was visually inspected.
- Kernel `--verdict` and the Lean companion remain unavailable without the
  previously documented Lean toolchain; no stronger proof claim is made here.

## Files

- `Main.bend`, `Controls.bend`: native window and interaction.
- `FloatTensor.bend`: numerical adapter to the shared matrix layout.
- `Field.bend`: matrix probes and the illustrative toroidal material field.
- `Render.bend`: parallel volume rendering.
- `Hud.bend`: native bitmap labels, attribution, meters, and controls.
- `Snapshot.bend`, `Benchmark.bend`: deterministic headless entry points.
- `LAWS.bend`, `PROOF.bend`, `Check.bend`: distinct structural and runtime checks.

## Sources and attribution

- [RCCM-GfX-2, section 3.3, matrix lines 172–177](https://github.com/subtleGradient/rccm/blob/9cb777b2f23b387e875c1a03353a700d41afdb0e/RCCM-GfX-2.tex#L172-L177),
  Binyamin Tsadik Bair-Mosheh. The title/credit identifies the inspiration, not
  author endorsement or empirical validation.
- Bend's `bend guide shaders`, native `app_triangle_2d` and `app_ray_tracer_3d`
  demos informed API usage and the tile/fork strategy. The external Bend checkout
  was read only; its renderer/game assets were not vendored or modified.
