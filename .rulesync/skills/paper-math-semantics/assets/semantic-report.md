# Semantic transcription report

## Source and scope

- Document/version:
- Selected equation and page/TeX locator:
- Original LaTeX (copyable):
- Relevant definitions/prose:
- Extraction verified against:
- Out of scope:

## Symbols

| Source symbol | Code identifier | Domain | Units | Scope | Source evidence |
| --- | --- | --- | --- | --- | --- |

## Claims and assumptions

| ID | Definition / premise / claim / approximation | Precise reading | Source-stated / translator-proposed | Target declaration |
| --- | --- | --- | --- | --- |

## TODO / FIXME ledger

| ID | Kind | Locator | Question or defect | Affected declarations | Alternatives | Owner | Status / resolution evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Target mapping

Bend 2 is primary; Lean/mathlib is a supporting reference for identified gaps.
Do not include TypeScript unless explicitly requested. Use one row per claim AND
target; abstract-domain, exact-concrete, and approximate mappings must not share
one fidelity status.

| Claim ID | Target | Declaration | Fidelity: exact / approximate / unresolved | Availability: present / blocked | Check status |
| --- | --- | --- | --- | --- | --- |

## Bend components and ecosystem gaps

- Supported packages chosen and inspected APIs:
- Useful Bend component delivered:
- Carrier/domain, operations, and interpretation map:
- Required laws versus established instance laws:
- Uninstantiated dependencies and limitations:
- Supporting Lean concept and the gap it clarifies:

Prefer supported packages, then an explicit generic algebra interface or scoped
semantic component. Missing `Real` is not a blanket no-Bend outcome. Never invent
an API as if it already exists; proposed upstream APIs are proposals.

| Gap ID / affected declaration | Required operation and law | Searched package/version or revision evidence, locator, search limits | Current workaround / dependency | Minimal proposed upstream API | Testable acceptance criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |

Record "not searched" for unperformed searches, not "unavailable". Acceptance
criteria must cover the declared domain and laws, not just successful compilation.
Distinguish catalogued / API-inspected / locally checked dependencies, and
arithmetic coverage / proof coverage / Bend-version compatibility. Begin with
the user-supplied Bend package catalog; a bend-mathlib-only search is insufficient.

## Validation

| Check | Tool/version and command | Result | What this does NOT establish |
| --- | --- | --- | --- |
| Source extraction | | not run | Intended meaning |
| Semantic review | | pending | Truth of claim |
| Bend checking | | not run | Cross-language equivalence |
| Lean reference checking (if used) | | not run | Fidelity to the paper |
| Proof obligations | | pending / not attempted | Empirical validity |

## Author handoff

- First unresolved question:
- What can proceed independently:
- Useful Bend result and next actionable upstream gap:
- What a proof process would receive:
- What an empirical-testing process would still need:
