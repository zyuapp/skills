# Skills

Workspace for shared skill definitions and related tooling.

## Available Skills

All skills in this repository are manual-invocation only. Invoke them by name,
for example `$ask-for-clarity`; their descriptions intentionally avoid automatic
trigger guidance.

- `ask-for-clarity`: asks only the blocking clarification questions needed to
  proceed, with a stated assumption for each question.
- `codex-review`: runs native `codex review` at high reasoning effort by
  default, captures the verbose transcript, and returns a concise Markdown
  table of findings. Use `--effort` or `CODEX_REVIEW_EFFORT` to tune effort.
- `explain-yourself`: explains the branch diff against the base branch,
  focusing on what changed and why rather than a line-by-line recap.
- `next-increment`: recommends the next small, reviewable implementation slice
  from the latest default branch and the relevant plan.

## License

MIT
