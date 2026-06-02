---
name: ask-for-clarity
description: Manual invocation only. Use only when the user explicitly invokes $ask-for-clarity or asks to use the ask-for-clarity skill by name; do not trigger automatically from task context.
---

# Ask For Clarity

Invocation: manual only. Do not select this skill unless the user explicitly invokes `$ask-for-clarity` or asks for this skill by name.

Use this skill when missing information would change the implementation, output, or decision in a material way.

Ask only the critical question needed to proceed. Do not ask for nice-to-have preferences when a reasonable assumption would keep the work moving.

For each question:

- State the assumption you would otherwise make.
- Ask the user to confirm or correct it.
- Keep the question short and specific.

If several questions are possible, ask the highest-impact one first. After the user answers, reassess whether another question is still blocking.

If a reasonable assumption is low-risk, state it and continue instead of stopping.
