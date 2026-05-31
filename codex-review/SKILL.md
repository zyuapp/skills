---
name: codex-review
description: Run the Codex CLI review workflow for the current Git worktree, usually against the default branch with `codex review --base origin/main`, and present the review findings as a concise Markdown table. Use when the user asks Codex to review current changes, review a branch against main/default, run `codex review`, or format Codex CLI review output without applying fixes.
---

# Codex Review

Use this skill to run Codex CLI review and report only the review results. Do not fix, edit, commit, or stage code unless the user asks separately.

`codex review` does not currently expose a quiet/suppress-output option. Always use the bundled wrapper instead of running `codex review` directly. The wrapper preserves the native `codex review` feature, captures its noisy transcript internally, and prints only the parsed Markdown table.

## Workflow

1. Confirm the working directory is the repository to review.
2. Run the bundled formatter from that repository:

```bash
python3 <codex-review-skill-dir>/scripts/codex_review_table.py --base origin/main
```

3. Return the script's Markdown table to the user.
4. If the script reports no findings, say that Codex review reported no findings.

## Base Branch

Default to `origin/main`. If that ref does not exist, rerun with the repository's default remote branch when it is obvious from Git metadata, for example `origin/master`.

Use `--uncommitted` for staged, unstaged, and untracked local changes. Use `--commit <sha>` for a single commit. Otherwise use `--base <ref>`, defaulting to `origin/main`.

## Output Rules

- Preserve Codex review's substance; only reformat it.
- Do not add your own findings unless clearly labeled outside the table.
- Do not include the full raw Codex transcript unless parsing fails or the user asks for it.
- Keep each table row short. Put long explanations below the table only when needed.
