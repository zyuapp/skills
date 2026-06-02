---
name: write-plans
description: Manual invocation only. Use only when the user explicitly invokes $write-plans or asks to use the write-plans skill by name; do not trigger automatically from task context.
---

# Write Plans

Invocation: manual only. Do not select this skill unless the user explicitly invokes `$write-plans` or asks for this skill by name.

Use this skill when the user wants a plan written into the repository.

## Workflow

1. Find the repository's existing plan location.
   - Prefer an existing `.plans/`, `plans/`, `docs/plans/`, or similar planning directory.
   - If none exists, create `.plans/`.
2. Write one self-contained `.html` plan file.
   - Use a plain engineering-memo style unless the user asks for a poster, landing page, or highly designed artifact.
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
- Print CSS.
- Responsive tables that remain readable on mobile.

Default to a plain engineering memo style: neutral background, readable sans-serif typography, compact metadata, semantic sections, numbered implementation steps, and restrained borders. The result should look like a plan someone would present in a meeting, not a generated landing page or visual artifact.

Avoid hero layouts, decorative counters, badges, icons, gradients, patterned backgrounds, negative letter-spacing, and visual flourishes that compete with the plan content.

Write like a practical engineering memo:

- Lead with the conclusion or recommendation, then give evidence.
- Keep section titles literal and useful. Prefer `Overview`, `Current State`, `Implementation Steps`, `Verification`, `Risks and Assumptions`, and `Expected Outcome`.
- Make implementation steps specific enough to execute: mention modules, files, commands, checks, or ownership boundaries when known.
- Do not use generic filler such as "leverage synergies", "robust scalable solution", "seamless experience", or vague transformation language.
- Do not over-explain obvious process. A presentable plan should read like it was written for a project review, not generated to fill space.

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

Before finishing, scan the HTML/CSS for generated-looking artifacts:

- No decorative heading counters, number bubbles, patterned backgrounds, hero sections, icon systems, pill-heavy status rows, oversized badges, negative `letter-spacing`, excessive shadow, or excessive accent color.
- Long tables remain readable on desktop and scroll horizontally on mobile.
- The file works in light mode, dark mode, and print mode.

When Browser is available and the target is local, open the finished HTML file in the in-app browser before responding. Check that the title, section numbers, metadata cards, tables, and mobile-width layout render cleanly. If browser verification is unavailable, say that and still perform the static scan above.
