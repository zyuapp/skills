---
name: quality-check
description: Thorough maintainability and code-quality review of the current session or branch diff — covers duplication and missed reuse, refactoring opportunities, domain/layering boundary violations, test quality, and spaghetti/complexity. This is a quality review, not a bug or security hunt: by default it reports issues and never fixes them, but pass --fix to apply accepted findings after the report, verify them, and commit the resulting local fixes. Use whenever the user asks for a quality check, quality review, maintainability review, test-quality review, refactoring-opportunity review, or a review of the current session's or branch's changes — even if they just say "review my changes" in a cleanup or maintainability context. Run the review in fresh subagents, one per review angle, and report findings; with --fix, apply accepted findings after the report and commit verified fixes.
---

# Quality Check

Run a fresh-context quality review of the current changes and report what's worth fixing. The value of this skill is a second pair of eyes that did **not** write the code: a reviewer carrying no memory of why the change was made judges it on what's actually on disk, the way a future maintainer will.

Because that objectivity is the whole point, the **review** only finds and reports — reviewers never edit files, apply patches, run formatters that write, commit, or push. Mixing fixes into the review would destroy the audit trail and bias the reviewer toward defending its own edits.

Applying fixes is therefore a separate, opt-in step. By default this skill reports and stops. Only when the user passes `--fix` does a fix phase run, and only **after** the report has been delivered — see [Fix phase](#fix-phase-only-with---fix). The fresh reviewers themselves still never touch the code, with or without `--fix`.

## Arguments

- `--fix` — after the report is delivered, apply the accepted findings to the working tree, verify them, and commit the resulting local fixes (see [Fix phase](#fix-phase-only-with---fix)). Without this flag, the skill reports and stops.

Any other argument is treated as a scope or focus hint from the user (e.g. a path, a single angle, "tests only") and passed through to scope selection and the reviewers as an explicit constraint.

## Scope: what this reviews

In scope: maintainability, duplication and missed reuse, refactoring opportunities, domain/layering boundaries, test quality, and complexity/spaghetti.

Out of scope: correctness and logic bugs, security vulnerabilities, and performance regressions. Those need a different kind of review and a different mindset, and chasing them here dilutes the quality pass. If a serious correctness or security problem is obvious in passing, note it in one line under Open Questions and move on — don't go hunting.

## How it runs

This skill uses a **coordinator** and several fresh **reviewers**:

- The **coordinator** is the agent that invokes this skill. It selects scope, spawns reviewers, then merges and reports. It does not perform the review itself.
- Each **reviewer** is a fresh subagent assigned exactly one angle. Reviewers rebuild all context from git and the filesystem — they are given no prior conversation, no implementation summary, and no remembered diffs, because inherited assumptions are exactly what a fresh review exists to catch. Reviewers do not spawn further subagents and do not load this skill; the coordinator has already done that.

Spawn the reviewers in parallel when the tooling allows. For a very small diff, it's fine to use fewer reviewers when splitting would only duplicate work — but still cover every angle that the diff touches.

If the coordinator has no subagent capability, stop and tell the user the skill can't run as specified, since the fresh-reviewer split is what makes it work. (This check is for the coordinator only; reviewers should not re-check it.)

## Scope selection

Determine the review base before reading the diff:

1. Find the repository root with `git rev-parse --show-toplevel`.
2. Find the default branch from `origin/HEAD` when available, falling back to `origin/main`, `origin/master`, `main`, then `master`.
3. Find the current branch's upstream with `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`.
4. If an upstream exists and it is not the default branch, use the upstream as the base. Otherwise use the default branch.
5. Compute the comparison point: `git merge-base HEAD <base-ref>`.
6. Include uncommitted staged, unstaged, and untracked files — they are part of the current session.

Capture at least:

```bash
git status --short
git merge-base HEAD <base-ref>                       # call this <mb>
git diff --find-renames --stat <mb> HEAD
git diff --find-renames <mb> HEAD
git diff --cached --find-renames
git diff --find-renames
git ls-files --others --exclude-standard
```

If a command is unavailable or there is no usable merge base, state the limitation and use the best available diff without guessing.

The diff is the **starting point, not the boundary**. A quality problem is often only visible through the code around the change: call sites, existing helpers, sibling modules, tests, and ownership boundaries. Read enough surrounding code and existing codebase patterns to tell a real issue from local preference, and don't restrict findings to the lines the diff happens to touch.

## Review angles

Each angle below is self-contained. When delegating (next section), paste the full block for the assigned angle into the reviewer's prompt — this is what gives a fresh reviewer the methodology, not just a label.

### Angle A — Maintainability, Duplication, Reuse, Refactoring

Look for:
- Code that is hard to maintain, over-abstracted, under-abstracted, or awkwardly coupled.
- Logic duplicated within the diff.
- Logic that duplicates helpers, services, components, queries, schemas, validators, fixtures, or test utilities that already exist in the codebase. Before claiming duplication, search for the canonical implementation with `rg`, the import graph, and the file tree — a duplication finding is only as good as the search behind it.
- New abstractions that are pure pass-through wrappers or that rename an existing API without adding behavior.
- Missed reuse where extracting or reusing a focused abstraction would materially cut complexity.
- Refactors that would make the change smaller, clearer, or more aligned with existing patterns.

### Angle B — Domain Boundaries / Layering

First decide whether the codebase has meaningful boundaries to respect: look at package/module layout, domain names, bounded contexts, service layers, feature modules, dependency-direction rules, architecture docs, lint rules, and import conventions. If it is not boundary-oriented, say so briefly and only flag obvious ownership problems.

If it is, check whether the change crosses boundaries it shouldn't:
- Domain logic placed in UI, transport, persistence, infrastructure, or shared-utility layers.
- Feature-specific behavior leaking into generic/shared modules.
- Cross-domain imports that bypass an established public API.
- Tests reaching through layers in a way the production code avoids.
- Shared helpers that secretly encode one domain's assumptions.

Name the more appropriate owning module or layer when the codebase makes it clear.

### Angle C — Test Quality

Assess whether the tests give the right confidence for the changed behavior:
- Under-testing: missing coverage for core behavior, edge cases, integration boundaries, regressions, failure paths, migrations, concurrency, or user-visible workflows.
- Over-testing: brittle assertions, duplicated cases, implementation-detail checks, snapshot churn, or tests that lock down incidental structure.
- Mocking quality: mocks that stub out the very thing under test, mocks that re-implement production logic, mocks that hide integration risk, or missing isolation where a real external effect leaks in.
- Confidence: would the current tests actually fail for the most likely real regression in this diff? If not, that's the finding.

Read the existing test style and helpers before recommending new tests. Don't ask for tests that merely prove a removed feature is gone.

Calibrate the severity of a missing-tests finding to the codebase's own testing bar. In a repo with no harness, or one that doesn't test code comparable to the change, a coverage gap is usually **low** — name it, but don't rate it as if there were a suite to extend. Reserve higher severity for untested behavior that is both genuinely risky and out of step with how similar code is already tested here.

### Angle D — Spaghetti / Complexity

Look for code that became hard to follow:
- Functions, components, files, or tests too long for their responsibility.
- Dense branching, nested conditionals, nested ternaries, conditional object-spread builders, or expression-only construction where explicit control flow would read more clearly.
- Scattered flags, modes, nullable state, or special cases that force the reader to track many paths at once.
- Sequential orchestration or partial updates that make state hard to reason about.
- Complexity piled into an already-busy module instead of moved behind a clearer seam.

Flag complexity growth even when behavior looks correct, when it makes future changes materially harder.

## Delegating to reviewers

Give each reviewer the repository path, the assigned angle's full block from above, and any explicit user constraints — nothing else. In particular, do **not** pass the coordinator's opinions, suspected findings, an implementation summary, or another reviewer's results. Methodology (how to look) helps a fresh reviewer; conclusions (what you think is wrong) just bias it.

Use a prompt like:

```text
You are a fresh delegated reviewer for a quality-check run.

Repository: <repo-path>
Assigned angle: <angle name>

<paste the full Angle block here — the "Look for" list and its guidance>

Rebuild all context from git and the filesystem; rely on no prior conversation or
implementation memory. Select scope yourself, read the diff and changed files from
scratch, and treat the diff as the starting point, not the boundary — inspect call
sites, existing helpers, sibling modules, tests, ownership boundaries, and relevant
architecture before judging. Don't limit findings to lines the diff touched when the
issue is only visible through nearby code or codebase patterns.

Finding an issue early does not end the review; work the whole angle and check whether
each issue pattern repeats elsewhere in the touched area. But report only findings you'd
defend to the author — see severity and calibration below. For each finding give
file:line, the problem, the evidence, and a non-implementing suggested direction. Do not
modify any files. If you find nothing for your angle, say so and include the base/merge-base
you used.

Severity: blocker = will actively impede maintainers very soon (data-shaped duplication
that will drift, a boundary breach that forces future violations). high = clear, compounding
complexity, duplication, or coupling. medium = a real but contained issue. low = optional
polish. Quality findings are rarely blockers; reserve it.

Calibration: a short report the author trusts beats a long one they skim and ignore.
Report issues you can back with evidence; drop low-conviction nits and matters of taste
rather than padding. Thoroughness means chasing real issues and their siblings to ground —
not inflating the count.
```

## Merging and reporting (coordinator)

Merge the reviewers' results: dedupe overlapping findings (the same long function may surface under both maintainability and complexity — keep one entry with the strongest evidence), resolve severity disagreements toward the more conservative call, and order by severity. Don't invent findings no reviewer reported; if you add or adjust one, re-read the code yourself first and hold it to the same evidence bar.

Lead with findings, ordered by severity:

```text
Findings
- Severity: <blocker|high|medium|low>
  Location: <file:line>
  Problem: <specific quality issue>
  Evidence: <what in the diff/codebase proves it>
  Suggested direction: <non-implementing guidance>

Open Questions
- <only if needed — including any correctness/security issue noticed in passing>

Review Notes
- Base used: <base-ref and merge-base>
- Included uncommitted changes: <yes/no>
- Domain-driven codebase: <yes/no/partial and why>
- Test confidence: <brief assessment>
```

Severity rubric (use consistently across findings):
- **blocker** — will actively impede maintainers very soon; rare for a pure quality issue.
- **high** — clear, compounding complexity, duplication, or coupling that will cost real time.
- **medium** — a genuine issue, but contained and not spreading.
- **low** — optional polish; include only when evidence-backed, not as filler.

If there are no findings, say so plainly and still include the Review Notes, plus any residual risk from tests you couldn't run or context you couldn't reconstruct.

## Fix phase (only with `--fix`)

This phase runs **only** when the user passed `--fix`, and **only after** the report above has been delivered. The report is the audit trail; it is never skipped, edited, or folded into the fixing. If `--fix` was not passed, stop after reporting.

The coordinator applies the fixes — the fresh reviewers stay report-only so their objectivity is never compromised. Work from the merged, deduped findings list:

1. **Select what to fix.** Fix findings in severity order (blocker → high → medium → low). Apply only findings that have a concrete, mechanical, low-risk direction. **Skip** — and say you skipped — any finding that is a matter of taste, is low-conviction, needs a product or architecture decision, requires removing/changing public API or behavior, or whose fix would be larger or riskier than the problem. When in doubt, leave it for the user.
2. **Apply.** Make the smallest change that resolves each finding, matching surrounding code style and existing codebase patterns. Group edits that touch the same file or the same root cause so the result stays coherent. Do not bundle in unrelated cleanups the review didn't flag.
3. **Verify.** After editing, re-run whatever the repo makes cheap and relevant — formatter, linter, type-check, the affected tests. Report what you ran and the result. If something now fails because of a fix, fix it or revert that finding rather than leaving the tree broken.
4. **Commit verified fixes.** If fixes were applied and verification passes, create one normal local commit containing only the `--fix` changes. Use the repository's commit-message conventions when they are documented, otherwise use a concise scoped message such as `fix: address quality-check findings`. Never use `--no-verify`. If commit hooks format files or make other mechanical changes, review and include those hook changes in the same commit as long as they are part of the quality-check fix. If verification fails and cannot be fixed within scope, do not commit; report the failure and leave the working tree for the user.
5. **Stop short of publishing.** Do not push unless the user explicitly asks. The `--fix` flag authorizes a local commit only, not publishing or PR updates.

Then report the fix outcome, keyed back to the findings:

```text
Fixes applied
- <file:line> — <finding> → <what changed>

Skipped (left for you)
- <file:line> — <finding> → <why not auto-fixed>

Verification
- <commands run and their result, or what couldn't be run and why>

Commit
- <commit SHA and subject, or why no commit was created>
```

The original Findings report stays above this section unchanged, so the reader can always see what was flagged independently of what was fixed.
