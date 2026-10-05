# Provenance and boundaries

## Sources

| Source | Evidence class | Use / limitation |
| --- | --- | --- |
| User's paper-semantics discussion in this thread | User request | Precise claims first; proofs later; English identifiers; copyable syntax; author TODOs; stories separate; vortex interest |
| User's Bend-first correction | User request, supersedes initial target ordering | Bend 2 primary; Lean supporting reference for breadth gaps; no TypeScript by default; useful Bend components plus actionable ecosystem gaps; asymmetrical metric tensor requested |
| [User-supplied Bend package catalog](https://raw.githubusercontent.com/lilalittle/bend-packages/refs/heads/main/README.md) | Mutable discovery source; package entries reported by parent, not locally inspected or checked in this skill update | Candidates include bend-kit-bignum (bigint/decimal/rational), bend-ml-tensor@0.1.2.0, bend-tensors@0.0.0.2, and lawful stdlib; verify revisions/APIs and Bend compatibility before use; arithmetic availability does not establish proof coverage or Real semantics |
| [Mathlib naming](https://leanprover-community.github.io/contribute/naming.html) | Library convention | Reuse names and semantic objects; propositions/types UpperCamelCase, ordinary value definitions lowerCamelCase, proofs snake_case |
| [Mathlib style](https://leanprover-community.github.io/contribute/style.html) | Library convention | Explicit argument/return types and conventional declarations |
| `bend guide`, `bend version`, `bend --help` on Bend 2.0.35 | Version-specific language documentation, observed during bootstrap | Plain command checks then runs main; `--check-only` runs nothing; `--verdict` rechecks with proven kernel. No kernel verdict was run for this fixture |
| [bend-mathlib guide](https://raw.githubusercontent.com/bendlib/bendlib/refs/heads/main/plugins/bend-mathlib/skills/bend-mathlib/SKILL.md) | Mutable library documentation, consulted during bootstrap | Not a pinned dependency or executable evidence; similar names do not establish mathlib coverage parity |
| [OpenStax 14.6](https://openstax.org/books/university-physics-volume-1/pages/14-6-bernoullis-equation) and [UT Austin Bernoulli lab](https://caee.webhost.utexas.edu/prof/kinnas/319LAB/Lab/lab%204-Bernoulli%27s%20equation/4-Bernoulli.htm) | Textbook / university teaching sources | Bernoulli expression and restrictions on streamline scope |
| Bernoulli starter fixture | Translator-created example | Uses the background sources above; not evidence about an absent paper or applicability to the user's vortex |

## Boundary decision

Create an experimental standalone skill: paper-to-semantic-declarations has a
distinct trigger and failure mode (a well-typed mistranslation).

The corrected target policy is Bend-first, not mathlib-first. Prefer inspected
supported packages, then explicit generic algebra interfaces or bounded semantic
components. Lean helps specify missing concepts; it does not replace Bend output.
Package absence must be supported by versioned search evidence and search limits,
not inferred from an unchecked fixture. No general-purpose AST or new mathematical
meaning is licensed by this fallback. Required interface laws are dependencies,
not automatically source premises or proved concrete-instance laws.

| Neighbor | Owns | This skill does not duplicate |
| --- | --- | --- |
| bend-mathlib | Finding/using supported Bend definitions and proved lemmas | Proof construction; this skill records semantic requirements and upstream gaps without claiming new lemmas proved |
| create-skill / skill-research | Skill packaging and evaluation | General skill governance |
| Story-oriented teaching (future) | Motivation and explanatory scenarios | Required story generation |
| Formal proof workflow (future) | Establishing precise claims | Completing proof obligations |
| Empirical research (future) | Testing predictions against observations | Physical validation |

Tactical empathy is out of scope: author questions here are technical review
items, not a resistance/persuasion workflow.

## Independent dimensions

Do not collapse these axes into a single "verified" status:

| Dimension | One side | Other side |
| --- | --- | --- |
| Source | Supplied paper | Constructed fixture |
| Interpretation | Resolved | Ambiguous |
| Representation | Exact | Approximate |
| Target | Supported | Blocked |
| Domain | Concrete intended carrier | Explicit abstract carrier with unresolved instantiation |
| Algebraic laws | Required dependency | Established instance evidence |
| Checking | Run | Not run |
| Evidence | Proposition stated | Proposition proved |
| Physics | Mathematical consequence | Empirically supported prediction |

## Promotion gate

Keep experimental until the casebook is exercised on supplied PDF and TeX
examples, a reviewer checks source correspondence, and generated declarations
are checked in pinned Bend toolchains, with supporting Lean checks when used.
Review useful Bend output and actionable gap criteria as well as source fidelity.
Syntax checks alone do not promote the skill.
