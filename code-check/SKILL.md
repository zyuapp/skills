---
name: code-check
description: Manual invocation only. Use only when the user explicitly invokes $code-check or asks to use the code-check skill by name; do not trigger automatically from task context.
---

# Code Check

Invocation: manual only. Do not select this skill unless the user explicitly invokes `$code-check` or asks for this skill by name.

Use this skill to review current changes for code quality. This is not a correctness review; focus on whether the code will be easy to understand, modify, and maintain.

## Workflow

1. Identify the comparison range.
   - Prefer the repository's default branch from Git metadata.
   - Fall back to `origin/main`, then `origin/master`, when the default branch is not obvious.
2. Inspect the changed files and nearby call sites.
3. When available, use an independent review pass or subagent for a second opinion.
4. Report only issues that materially improve maintainability.

## Review Focus

Look for:

- Unnecessary complexity or unclear control flow.
- Duplication that hides intent or makes future changes risky.
- Naming, structure, or boundaries that conflict with existing code patterns.
- Missing local abstractions where repeated logic is already emerging.
- Refactors that reduce cognitive load without changing behavior.

Avoid:

- Bug hunting unless the maintainability problem directly creates a defect risk.
- Style preferences that are not backed by local convention.
- Large rewrites that are not justified by the diff.

## Output

Lead with findings, ordered by severity. For each finding include:

- Severity.
- File and line.
- What makes the code harder to maintain.
- The smallest practical improvement.

If there are no material findings, say that clearly and mention any residual risk or area not reviewed.
