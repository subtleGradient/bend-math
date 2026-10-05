# Questions for the author / implementation reviewers

All source locators refer to `RCCM-GfX-2.tex` at commit
`9cb777b2f23b387e875c1a03353a700d41afdb0e`, not a newer draft.
These are questions about precise readings, not conclusions about the full theory.

| ID | Source locator | Question and why it matters | Affected declaration | Alternatives | Owner / status |
| --- | --- | --- | --- | --- | --- |
| TODO[RCCM-001] | Section 1, lines 95–104 | Is Omega only the exterior derivative of the Clebsch component, as written, or the total velocity's vorticity? The latter generally also contains d(v_perp). | Future vorticity definition | Clebsch-only / total plus transverse term / extra restriction on v_perp | Author; open |
| TODO[RCCM-002] | Section 1, lines 91–102 | What is the spatial domain, regularity, and treatment of defects? Is the Clebsch representation local or global? | Future differential-form fields and d-squared claim | Smooth patch / punctured domain / singular or weak model needing its own rules | Author; open |
| TODO[RCCM-003] | Section 3, lines 133–151 | What precise object is the asymmetric "metric"? Which tensor raises/lowers indices, and what explicit map establishes the stated Clifford isomorphism? | Future matrix-to-geometry interpretation | General covariant rank-2 tensor with separate symmetric metric / specified generalized geometry | Author; open |
| TODO[RCCM-004] | Section 15, lines 2075–2077 | How is saturation at r = ct reconciled with fraction (1 - exp(-1))^2? This is about the boundary or formula, not mere rounding. | pressureFraction interpretation and future boundary claim | Asymptotic r/(ct) -> infinity / revised finite-boundary profile / different evolving limit stated explicitly | Author; open; numeric formula check recorded |
| TODO[RCCM-005] | Section 15, line 2075 and Brout2022 citation | Which exact Pantheon+ release, subset, observable transformations, calibration parameters, likelihood/covariance, and fitting code produced this curve? | Future data-fit tests | Reconstruct original fit / author supplies artifacts; no fabricated measurements | Author; open |
| TODO[RCCM-006] | Target mapping | Which verified Bend domain and real-exponential implementation can faithfully express this scalar model? | Exact Bend pressure profile | Existing supported library / explicitly scoped approximation as separate model | Library investigation; blocked, no candidate verified |
| TODO[RCCM-007] | PressureProfile.lean | Which Lean/mathlib versions should check the declarations? | All Lean declarations | Adopt a pinned existing project / configure one deliberately | Project tooling; not run |

## Source-derived identity, not an RCCM physical conclusion

For smooth fields on an appropriate domain, the usual exterior-derivative rules
expand the selected Clebsch term as:

```text
exteriorDerivative(rotationWeight * exteriorDerivative(rotationPotential))
= wedge(exteriorDerivative(rotationWeight), exteriorDerivative(rotationPotential))
  + rotationWeight * exteriorDerivative(exteriorDerivative(rotationPotential))
```

The last term vanishes by `d(d scalar) = 0`. This accounts for the printed
Clebsch-component formula; it does not show that every velocity admits that global
representation or establish the proposed interpretation in terms of mass.

Taking the derivative of the FULL velocity would instead leave:

```text
exteriorDerivative(transverseVelocityForm)
+ wedge(exteriorDerivative(rotationWeight), exteriorDerivative(rotationPotential))
```

The paper's word "internal" may already intend the narrower meaning. Ask rather
than silently insert or delete a term.

## Resolution record

No author decisions received yet. Preserve the original source, question, chosen
interpretation, and evidence when an item is resolved. Proof work dependent on
these meanings remains blocked until the corresponding statement is fixed.
