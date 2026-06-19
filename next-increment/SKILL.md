---
name: next-increment
description: Recommend the next small, reviewable implementation slice from the current repository state and relevant plan. Use this skill when the user wants to choose what to build next, split work into a focused PR-sized increment, or identify the safest next step without implementing it yet.
disable-model-invocation: true
---

# Next Increment

Use this skill to choose the next focused implementation slice.

The default branch is the source of truth for what has landed. Treat the current branch as local context only unless the user explicitly says it represents the baseline.

## Workflow

1. Detect the repository default branch from Git metadata.
   - Prefer `refs/remotes/origin/HEAD`.
   - Fall back to `origin/main`, then `origin/master`.
2. Fetch the default branch only when network access and user permissions allow it. Do not merge, rebase, reset, or checkout over user work.
3. Inspect the relevant code and the implementation plan.
4. Identify the smallest useful increment that can stand alone in review.
5. Recommend the increment. Do not implement unless the user asks.

## Sizing

Prefer a PR under 500 changed lines including tests. Aim closer to 300 changed lines when the task is likely to grow during implementation.

The increment should have:

- A clear user-visible or developer-visible outcome.
- A narrow file surface.
- Obvious verification steps.
- Minimal dependency on future unmerged work.

## Output

Give one recommended increment, not a menu, unless the choice depends on product intent only the user can answer.

Include:

- Scope.
- Why this is the right next slice.
- Expected files or areas touched.
- Verification plan.
- Risks or assumptions.
