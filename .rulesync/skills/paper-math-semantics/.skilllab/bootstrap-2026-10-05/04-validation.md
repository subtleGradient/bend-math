# Bootstrap validation and open loops

## Observed

- Read installed `bend guide` before authoring the workflow.
- Structural check passed: skill metadata/name/description bounds, fewer than
  500 skill lines, no trailing whitespace, local Markdown links resolve inside
  the portable skill folder, and no `sorry`/`admit`/`axiom` in the Lean asset.
- `git diff --check` reported no tracked-diff whitespace errors. New untracked
  skill files were checked separately by the structural check.
- Existing project `bend PROOF.bend`: `ALL PROOFS CHECK`, followed by
  `Use --verdict for mathematical validity.` This is the unchanged project's
  proof gate, NOT validation of Bernoulli, the Lean asset, or this skill's output.
- `rulesync generate`: could not run (`rulesync: command not found`).
- Lean is not on PATH; the Lean asset was not typechecked.
- No commit, installation, or global skill configuration changes made.

## Deliberately not claimed

- No user paper was transcribed.
- No real-number Bend counterpart was implemented.
- No physical theorem was proved; no vortex simulated.
- No PDF/TeX end-to-end casebook runs or author semantic review completed.
- Skill source exists but is not installed/generated for an agent target.

## Next smallest test

Supply one equation plus its definitions, then run the workflow with a pinned
Bend 2 environment and inspected package dependencies, with Lean/mathlib as a
supporting reference where useful. Review author-facing questions before starting
proof work. Keep the skill experimental until actual case results are recorded.

## Bend-first correction validation scope

The workflow, report, provenance/boundaries, intent mirror, constitution, and
planned casebook were revised for Bend-first output and actionable package gaps.
The old Bernoulli slice remains unchecked and incomplete; no completed Bend
implementation was retroactively invented. Its default TypeScript snippet was
removed. Package catalog entries are discovery candidates, not inspected/checked
dependencies in this update. No installs, generation, or target changes were made.
New casebook rows remain planned, not passed; runtime/semantic validation is still
required before promotion.

Structural validation for the correction passed across all ten skill files:
frontmatter name/description bounds, fewer than 500 skill lines, no trailing
whitespace, local Markdown links resolving, no default TypeScript fixture code,
no `sorry`/`admit`/`axiom` in the retained Lean asset, and required gap columns.
`git diff --check` also passed, but the skill tree is untracked, so the explicit
file checks above are the evidence for its whitespace and structure. No Bend or
Lean runtime check was claimed for this documentation-only mutation.

## Review corrections

- Replaced the undocumented two-sample transformation with `BernoulliAt`, directly
  encoding the displayed equality to C. Conservation quantifiers remain blocked.
- Reclassified the future proof task as blocked on semantic decisions.
- Expanded the fixture ledger to include locators, declarations, alternatives,
  owners, and status; split the broad representation gap into four sub-items.
- Separated each target's fidelity, availability, and checking status.
- Added a no-execution initial Bend check and ordinary-checker/kernel distinctions,
  retaining the user's plain-command gate only after execution safety review.
- Added visible Lean "NOT RUN" status and observed Bend version 2.0.35.
- The review's missing-source and missing-validation-file findings referred to an
  earlier snapshot: both sources and this file were added before it completed.
