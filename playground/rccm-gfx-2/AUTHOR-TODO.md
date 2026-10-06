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
| TODO[RCCM-008] | Sections 1–5 and 13.1 | Which closed density/momentum/energy system, EOS and stress law should advance the full continuum? The transverse vacuum subsystem does not close bulk-fluid dynamics. | Future coupled fluid solver | Author-selected conservative formulation and constitutive parameters; no invented pair-force substitute | Author; open |
| TODO[RCCM-009] | Cavitation limits in sections 4.1, 6.3 and 8 | What are the defect state, nucleation, moving-interface and topology-change rules, including mass/energy/spin exchange? | Future cavity solver | Explicit free-boundary or diffuse-interface model with stated assumptions and conservation budgets | Author; open |
| TODO[RCCM-010] | Section 3.3 matrix, lines 172–177; section 13.1, lines 1753–1779 | Confirm the axial/two-form convention. With A_0i=-alpha e_i, A_ij=-alpha epsilon_ijk b_k and Minkowski raising, the printed spacetime equations give e_t=-c curl b and b_t=+c curl e. How does the prose's curl/vorticity identification map to these coefficients? | Transverse baseline and future geometric interpretation | Baseline preserves the displayed matrix and documents its component convention; a different magnetic-vector convention must negate b consistently | Author; open; numerical choice documented in fluid/README.md |
| TODO[RCCM-011] | Handedness/field interpretation and pressure-gradient gravity claims | What are the conserved defect source/winding quantities and the signed, normalized coupling to electric and gravitational responses? | Future defect interaction experiments | Measure emergence from the chosen coupled equations; do not enforce the expected outcome with Coulomb/Newton particle forces | Author; open |

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

The user confirmed that the requested simulation has **three spatial dimensions
plus time**, not four spatial dimensions. This fixes the domain interpretation,
not the unresolved closures above. No author resolution of those closures has
been received. Preserve the source, question, chosen interpretation and evidence
when an item is resolved. Proof work dependent on those meanings remains blocked
until the corresponding statement is fixed.
