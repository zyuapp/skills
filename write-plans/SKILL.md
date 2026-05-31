---
name: write-plans
description: Create a self-contained implementation plan file in a repository. Use when the user asks to write, save, draft, or add a plan file for the current work.
---

# Write Plans

Use this skill when the user wants a plan written into the repository.

## Workflow

1. Find the repository's existing plan location.
   - Prefer an existing `.plans/`, `plans/`, `docs/plans/`, or similar planning directory.
   - If none exists, create `.plans/`.
2. Write one self-contained `.html` plan file.
3. Base the plan on the current discussion and the relevant code context.
4. Include an overview, implementation steps, verification, risks, and expected outcome.

## Content Requirements

The plan should be actionable without the conversation history.

Include:

- A concise title and one-sentence summary.
- Relevant repository, branch, and date metadata when known.
- Overview of the problem and intended outcome.
- Numbered implementation steps with files or areas to touch.
- Verification steps, including tests or manual checks.
- Risks, assumptions, and open questions.
- Expected outcome.

## HTML Requirements

Create a single HTML document:

- Inline CSS in a `<style>` block.
- No external JavaScript or CSS framework.
- Valid responsive layout with `<meta name="viewport" content="width=device-width, initial-scale=1">`.
- Clear semantic sections with stable `id` attributes.
- Readable typography, restrained color, and generous spacing.
- Light and dark color-scheme support.
- Accessible contrast for body text.

Use a polished engineering-memo style: calm typography, strong hierarchy, subtle dividers, and compact metadata. Avoid decorative effects that make the plan harder to read.

## Suggested Structure

Use these sections unless the task calls for something different:

1. Header.
2. Overview.
3. Implementation Steps.
4. Verification.
5. Risks and Assumptions.
6. Expected Outcome.

For each implementation step, include:

- Step title.
- Purpose.
- Files or areas likely to change.
- Concrete work items.
- Verification for that step when useful.

## Quality Bar

The file should look intentional when opened directly in a browser. Keep the design self-contained and durable, but prioritize plan clarity over visual flourish.
