---
name: land
description: >-
  Land requested bend-math changes on the main branch of
  subtleGradient/bend-math with focused verification and a normal push.
  Invoke only when the user explicitly requests landing or merging changes,
  including /land. Not for review, preparation, passing checks, or installing
  this skill.
disable-model-invocation: true
metadata:
  delta-action: land
---

# Land bend-math changes

## Intent and defaults

An explicit landing request supplies permission to commit, integrate, and
publish the requested changes. Proceed without asking for the same permission
again. Skill installation alone does not supply landing permission.

This workflow applies only to `subtleGradient/bend-math`. The recommended
destination is `origin/main`, using a normal, non-force push. Prefer the least
surprising result and keep this toy side project's workflow lightweight:
no extra pull request, release, package publication, or unrelated cleanup.

Resolve conflicts automatically when the intended result is clear. Preserve
independent edits on both sides. Pause for ambiguous intent, unsafe changes,
failed checks, or an unresolved contribution requirement.

## 1. Establish scope and destination

Work in the current attached repository, not a separate primary checkout.

1. Read applicable `AGENT.md`/`AGENTS.md` files and current contribution
   policies, templates, build configuration, and verification scripts.
2. Inspect the current branch, status, staged changes, uncommitted diffs,
   untracked files, and any unlanded commits. Include only changes covered by
   the request. This may include the newly installed landing skill when the
   request covers it. Do not use `git add -A` or silently include unrelated
   commits, edits, generated captures, or native binaries.
3. Inspect remotes. Confirm that `origin` resolves to
   `github.com/subtleGradient/bend-math` before publishing. `local` is a
   checkout backlink, not the publication destination. Stop on a different
   repository or unresolved target rather than guessing.
4. Check authentication and current destination requirements using read-only
   GitHub queries:

   ```sh
   gh api repos/subtleGradient/bend-math
   gh api repos/subtleGradient/bend-math/branches/main
   gh api repos/subtleGradient/bend-math/rulesets
   gh api repos/subtleGradient/bend-math/actions/workflows
   ```

   If protection or rulesets apply, inspect their applicable rules, not just
   their names. At setup, `main` was unprotected, there were no rulesets or
   workflows, and recent history used direct commits. These are observations,
   not permanent exemptions.
5. Honor applicable signing, contributor agreement, authorship, review,
   changelog, and submission requirements if introduced. Preserve their
   conditions. Obtain human-authored text when a policy specifically requires
   it; generated text plus approval is not equivalent. Do not disable
   protection, bypass reviews, or change signing configuration to land.

The root workflow makes `LAWS.bend` human-owned. Do not alter law statements,
remove proof obligations, or loosen checks to make landing succeed without
explicit approval for that separate change.
Source: [`README.md`](../../../README.md), “Workflow”.

## 2. Prepare the candidate without disturbing unrelated work

1. Fetch the current destination with `git fetch origin main`. Record its SHA
   and the initial branch/status before changing Git state.
2. Determine the precise requested patch and commits. If unrelated work or
   commits share the checkout, preserve them and prepare the candidate in a
   temporary Git worktree inside the current repository workspace, based on
   the freshly fetched `origin/main`. Do not auto-stash, reset, or rewrite a
   shared branch to obtain a clean tree.
3. Apply only the requested patch or commits. For a small uncommitted change,
   explicitly stage its paths or hunks and make a concise descriptive commit.
   There is no established required commit prefix or issue trailer. Use
   `GIT_EDITOR=true git commit -m "..."`; preserve configured signing.
4. Integrate current `origin/main` with fast-forward updates where possible,
   otherwise a normal merge or transfer of the scoped change onto the fresh
   base. Avoid rewriting existing shared history. Prefix commands that may
   open an editor with `GIT_EDITOR=true` and supply messages non-interactively.
5. Automatically resolve only clear conflicts. If choosing a side would
   discard behavior, change a human-owned law, or require a product decision,
   stop and explain the conflict. Do not use blanket “ours”/“theirs” resolution.

If no requested changes remain, verify whether they are already present at
the destination and report that result; do not manufacture an empty commit.

## 3. Verify the final candidate

Run checks in the candidate checkout after integration, not merely on the
pre-merge source. Record the candidate SHA, tool versions, commands, exit
statuses, and relevant output. If the candidate changes, rerun affected
checks. Do not treat pending, failing, missing, or unverifiable required checks
as success.

### Baseline

From the candidate repository root:

```sh
git diff --check origin/main...HEAD
bend PROOF.bend
```

The root proof target implements the law fillers and imports the expression
implementation and human-owned specification:
[`PROOF.bend`](../../../PROOF.bend), `diff_correct_aux` and
`Laws.diff_correct`; [`README.md`](../../../README.md), “Workflow”.
The ordinary checker must exit successfully with its version's clean proof
verdict and no open obligations or proof failures. Do not rely on exit status
alone or insist on an obsolete output string from an older Bend version.

For documentation- or skill-only changes, also review links, descriptions,
frontmatter when applicable, and unintended diff changes. Do not build native
apps solely for a documentation change.

### Vortex code changes

For changes to the vortex app or its shared tensor dependencies, run:

```sh
bend playground/rccm-gfx-2/tensor/PROOF.bend
bend playground/rccm-gfx-2/vortex/PROOF.bend
bend playground/rccm-gfx-2/vortex/Check.bend
bend playground/rccm-gfx-2/vortex/Main.bend --check-only
python3 -m unittest discover -s playground/rccm-gfx-2/vortex -p 'test_*.py'
mkdir -p playground/rccm-gfx-2/vortex/.build
bend playground/rccm-gfx-2/vortex/Main.bend -o playground/rccm-gfx-2/vortex/.build/vortex
```

Exact targets and implementations:
[`tensor/PROOF.bend`](../../../playground/rccm-gfx-2/tensor/PROOF.bend),
[`vortex/PROOF.bend`](../../../playground/rccm-gfx-2/vortex/PROOF.bend) law
fillers, [`vortex/Check.bend`](../../../playground/rccm-gfx-2/vortex/Check.bend)
`main` and failure-exiting `expect`,
[`vortex/Main.bend`](../../../playground/rccm-gfx-2/vortex/Main.bend) native
`main`, and
[`vortex/test_image_to_png.py`](../../../playground/rccm-gfx-2/vortex/test_image_to_png.py)
`ImageEncodingTests`. Command forms were checked against Bend 2.0.35
`bend --help` and Python `unittest discover --help`; recheck support if the
toolchain changes. Build output is ignored by
[`vortex/.gitignore`](../../../playground/rccm-gfx-2/vortex/.gitignore).

For a window/layout/rendering change, run a bounded native launch and inspect
the requested visual result if a desktop session is available. Close only the
process started for this check. Capture only its window, not the whole desktop.
If the necessary desktop or build dependencies are absent and no equivalent
evidence covers the final candidate, report the verification blocker instead
of claiming the visual fix passed.

The native app needs Bend's supported window/build backend. Python image
tests use the standard library and the local image encoder; there is no
Node/browser build to install.
Sources: [`vortex/Main.bend`](../../../playground/rccm-gfx-2/vortex/Main.bend)
and [`vortex/test_image_to_png.py`](../../../playground/rccm-gfx-2/vortex/test_image_to_png.py).

### Other code changes and toolchain limits

Use the affected area's actual proof target and existing runner rather than
assuming the vortex checks cover unrelated mathematics. Read its implementation
and supported arguments before adding a command.

For signed-chain changes, reuse the authoritative runner:

```sh
playground/signed-chains/verify.sh
```

Source: [`playground/signed-chains/verify.sh`](../../../playground/signed-chains/verify.sh),
its script-relative working directory, profile selection, and ordinary/kernel
gate implementation. It enforces Bend 2.0.27 and a Base digest by default.
The optional 2.0.34 candidate profile requires explicit selection; neither
profile accepts the Bend 2.0.35 observed at setup. Do not silently repin it,
select a candidate, substitute the ordinary checker, or download a toolchain
to bypass a failed runner. Report the mismatch when this runner is applicable.

For areas whose documented baseline is the ordinary checker, a passed ordinary
check is not a proven-kernel verdict. Missing Lean/BendTT does not establish
kernel success. Keep the ordinary baseline where the area allows it; where
kernel verification is required, missing or failing kernel execution blocks
landing.
Sources: [`tensor/GAPS.md`](../../../playground/rccm-gfx-2/tensor/GAPS.md),
`GAP-TOOL-001`, and
[`playground/signed-chains/verify.sh`](../../../playground/signed-chains/verify.sh).

### Required remote checks and reviews

Before landing, establish and satisfy all current required checks and reviews
for the actual candidate under the destination's rules. No remote CI existed
at setup, so do not invent a CI prerequisite in its absence.

If current rules require a pull request, publish the candidate to a normal
topic branch and use the required review/merge process rather than direct-push
bypassing it. Wait for every required check on the current candidate to pass,
and for required approvals. Starting checks or creating the pull request is
not landing. If checks or human review remain pending, report that the change
has not landed. Never use an admin bypass.

## 4. Land and confirm

1. Recheck the remote `main` SHA immediately before publication. If it moved,
   incorporate the newer destination into the candidate, resolve clear
   conflicts, and rerun applicable verification on the resulting candidate.
2. With all required checks passed, publish directly when rules permit:

   ```sh
   git push origin HEAD:refs/heads/main
   ```

   This must be a normal fast-forward push. On a non-fast-forward rejection,
   fetch, integrate, and verify again; never force-push. If concurrent changes
   repeatedly prevent a safe landing, report the blocker rather than retrying
   indefinitely.
3. Verify the destination through a fresh GitHub branch query and
   `git ls-remote --heads origin main`. Establish that the landed commit is the
   remote tip or an ancestor of it if another change landed afterward. When a
   policy-required pull request was used, verify its merged state and that
   the actual merge/squash commit is present on `main`.
4. Inspect the resulting status. Preserve unrelated edits and the original
   branch. Do not reset another checkout, delete user branches, or remove a
   temporary candidate worktree with uncommitted work. Report any retained
   temporary worktree so it can be inspected.
5. Report the destination, landed commit/link, scoped changes, and checks
   actually completed. Distinguish ordinary proofs, runtime tests, native
   builds, and visual evidence. If publication or verification failed, say
   the changes have not landed and name the specific blocker. A local commit,
   published topic branch, open pull request, or successful skill installation
   is not a successful landing.
