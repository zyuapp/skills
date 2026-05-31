# Skills

Workspace for shared skill definitions and related tooling.

## Available Skills

- `ask-for-clarity`: asks only the blocking clarification questions needed to
  proceed, with a stated assumption for each question.
- `code-check`: reviews recent changes for maintainability, readability,
  duplication, and consistency with local code patterns.
- `codex-review`: runs native `codex review` at high reasoning effort by
  default, captures the verbose transcript, and returns a concise Markdown
  table of findings. Use `--effort` or `CODEX_REVIEW_EFFORT` to tune effort.
- `next-increment`: recommends the next small, reviewable implementation slice
  from the latest default branch and the relevant plan.
- `write-plans`: creates self-contained repo-local HTML implementation plans.

## Install

Link the skills in this repo into the local Codex skills directory:

```bash
./install.sh
```

By default, the script creates symlinks in `${CODEX_HOME:-~/.codex}/skills`.
Set `CODEX_SKILLS_DIR` or pass `--target DIR` to install somewhere else, for
example `./install.sh --target ~/.agents/skills`.

The installer refuses to overwrite existing non-symlinked skills. Use
`./install.sh --dry-run` to preview changes, or `./install.sh --force` to
replace existing symlinks.

## Uninstall

Remove this repo's symlinks from the local Codex skills directory:

```bash
./uninstall.sh
```

The uninstall script only removes symlinks that point back to this checkout. It
skips real directories and symlinks owned by another checkout.

## License

MIT
