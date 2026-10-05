# Measurements, regression checks, and experiment plans

This is a proposed separate workflow, not an extension of the semantic skill into
empirical validation. No measurement dataset or physical run is included here.

## Evidence categories

- **Mathematical proof:** a formal consequence of precise premises.
- **Implementation regression:** selected inputs check the executable model.
- **Calibration/fit:** data used to choose the model, formula, or parameters.
- **Held-out evaluation:** observations not used in those choices.
- **Prospective experiment:** plan/analysis criteria recorded before new outcomes.
- **Simulation:** consequences of a model and numerical method, not new physical
  observations. Checking a model against a simulator built from the same equations
  is not independent confirmation of those equations.

Fitting data first is legitimate. It changes how the same data can later be used
as evidence: agreement with calibration data is not independent prediction.
Model-form selection also counts as fitting, not only numeric parameter fitting.

## Small conventional starting point

Use CSV for small tabular observations and a documented JSON sidecar for metadata.
These are standard encodings, not a universal scientific experiment schema.
Preserve raw source files; store transformations as separate reproducible artifacts.

Per dataset, capture:

- Stable identity, source URL/release/license, raw checksum.
- Column meanings, units, missing-value rules.
- Uncertainty meaning (standard uncertainty, confidence interval, etc.), including
  correlations or covariance when needed, not just independent error bars.
- Instrument/calibration/procedure or published-data provenance.
- Raw versus derived status and transformation code/version.
- Calibration, exploratory, or held-out role; disclose reuse and leakage.

Per experiment plan, capture:

- Model/parameter/code versions fixed before evaluation; provenance of fitted inputs.
- The observable, inputs, conditions, units, and measurement procedure.
- Quantitative predictions, uncertainty model, comparison/statistical method.
- Acceptance/rejection criteria and tolerances chosen before seeing new outcomes.
- Competing/baseline model where appropriate.

Per run, capture:

- Plan ID, run type (`physical` or `simulation`), actual conditions and outputs.
- Code/environment/random seeds, deviations from plan, timestamps.
- For simulations: grid/time step, solver, boundary/initial conditions, convergence
  checks and numerical uncertainty. Numerical tolerance is not measurement error.
- For physical runs: instrument and calibration information.

## Existing standards and their boundaries

| Format/convention | Use | Does not provide |
| --- | --- | --- |
| [CSV / RFC 4180](https://www.rfc-editor.org/rfc/rfc4180) | Small measurement tables; broadly interoperable | Units, uncertainty, provenance, train/test governance |
| [Parquet](https://parquet.apache.org/docs/) | Larger columnar tabular data | Physical meaning or experiment protocol |
| [HDF5](https://www.hdfgroup.org/solutions/hdf5/) or [netCDF](https://www.unidata.ucar.edu/software/netcdf/) | Large multidimensional simulation fields | Automatic empirical validation |
| [CF conventions](https://cfconventions.org/) | Established metadata for many climate/forecast-style arrays | A universal schema for all physics |
| [RO-Crate](https://www.researchobject.org/ro-crate/) | Package research files with provenance metadata | A complete experiment or statistical-analysis model |
| [SED-ML](https://sed-ml.org/) | Reproducible computational simulation experiments when the tools/models fit | Arbitrary physical laboratory execution or universal hypothesis testing |

Adopt specialized formats when their capabilities become useful. Do not create a
large framework before obtaining the actual measurements and analysis procedure.

## RCCM-specific first step

Resolve `TODO[RCCM-005]`: identify exactly what observations shaped the pressure
curve. Reproduce that calculation as a calibration regression before labeling any
new test "held out". Pantheon+ data can involve correlated uncertainties and
calibration/model dependencies; matching a few plotted points is not enough.

The Bend tensor fixtures here are intentionally **synthetic math/software
checks**, not a reconstruction of that fit and not evidence of physical validity.
