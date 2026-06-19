---
name: pr-description
description: >
  Create pull requests or rewrite PR descriptions. This is the go-to skill for anything PR-related:
  creating a new PR from the current branch, rewriting or improving an existing PR's title/body,
  or generating a description for a PR that's already open. Trigger whenever the user says things like
  "create a PR", "open a PR", "make a pull request", "push and create a PR", "update the PR description",
  "rewrite the PR body", "improve the PR", or references `/pr-description`.
  Also trigger when the user finishes a coding task and asks to submit, ship, or send it for review.
  Works with an optional PR number argument (e.g., `/pr-description 1234`).
disable-model-invocation: true
---

# PR Description Skill

Create pull requests or rewrite existing PR descriptions. Handles the full lifecycle — from pushing
your branch to generating a high-quality title and body from the diff and commit history.

## Step 1: Determine the target

Figure out whether you're working with an existing PR or creating a new one.

- **Explicit PR number** (e.g., `/pr-description 1234`): use that PR.
- **No argument**: check the current branch:
  ```bash
  gh pr view --json number,title,body -q '.number' 2>/dev/null
  ```
  - If a PR exists → you're **updating** it.
  - If no PR exists → you're **creating** one.

Identify the base branch. Check the repo's default branch:
```bash
gh repo view --json defaultBranchRef -q '.defaultBranchRef.name'
```
Use this as the base for diffs (e.g., `git diff <base>...HEAD`). If updating an existing PR, use
its base branch instead: `gh pr view <number> --json baseRefName -q '.baseRefName'`.

## Step 2: Preflight (create mode only)

When creating a new PR, verify the branch is ready before gathering context.

1. **Check for uncommitted changes:**
   ```bash
   git status --porcelain
   ```
   If there are staged or unstaged changes, stop and ask the user whether they want to commit first.
   Don't commit on their behalf — just flag it.

2. **Ensure the branch is pushed:**
   ```bash
   git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
   ```
   - If no upstream exists, push with tracking:
     ```bash
     git push -u origin HEAD
     ```
   - If an upstream exists, check if local is ahead:
     ```bash
     git status -sb
     ```
     If ahead, push:
     ```bash
     git push
     ```

3. **Verify there are commits to PR:**
   ```bash
   git log <base>...HEAD --oneline
   ```
   If empty, the branch has no new commits — tell the user there's nothing to open a PR for.

## Step 3: Check for a PR template

Search the repo for a PR template in these locations (in order):
1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/pull_request_template.md`
3. `docs/pull_request_template.md`
4. Any file inside `.github/PULL_REQUEST_TEMPLATE/`

**If a template is found**: use that template's structure exactly. Fill in each section based on
the PR context. Don't add extra sections or rearrange — respect the repo's conventions.

**If no template is found**: use the default format in Step 5.

## Step 4: Gather context

Collect all of these in parallel where possible:

| What | How |
|------|-----|
| Diff | `gh pr diff <number>` or `git diff <base>...HEAD` |
| Existing description | `gh pr view <number> --json body -q '.body'` (update mode) |
| Commit messages | `gh pr view <number> --json commits` or `git log <base>...HEAD --oneline` |
| Current title | `gh pr view <number> --json title -q '.title'` (update mode) |
| Changed files summary | `gh pr diff <number> --stat` or `git diff <base>...HEAD --stat` |
| Recent merged PR titles | `git log --oneline -10 <base>` (to match commit style) |

Read the diff carefully. Understand what changed and why before writing anything.

## Step 5: Generate title and body

### Title

- Keep under 70 characters
- Use conventional commit style if the repo uses it (check the recent merged PR titles from Step 4)
- Focus on the *what*, not the *how* — e.g., "feat(ecosystems): add Gradle version comparators"
  not "add GradleVersionComparator class and MavenVersionComparator class"

### Body

If a PR template was found in Step 3, follow its structure. Otherwise, use this format:

```markdown
## Problem

[1-3 sentences explaining WHY this change exists. What's broken, missing, or needed?
Link to issues/tickets if referenced in commits or the existing description.]

## Changes

| Component | What changed | Details |
|-----------|-------------|---------|
| `file-or-module` | Brief summary | Key implementation details the reviewer should know |
| ... | ... | ... |

## Testing plan

[Copy-paste commands a reviewer can run locally to verify the change.
Include the exact test commands with expected output.
If there are manual verification steps, describe them concretely.]

## Risks

[Bullet points covering: backward compatibility, scope limitations,
what could go wrong, dependencies on follow-up work.
If there are no meaningful risks, say "Low risk — [brief reason]".]
```

### Writing guidelines

- **Problem**: Derive from commit messages, existing description, and the diff. If the existing
  description already explains the problem well, preserve that context. Don't be generic —
  reference specific error messages, package names, or symptoms.
- **Changes table**: One row per logical unit of change (not per file). Group related file changes
  into a single row. The `Component` column should use backtick-formatted paths or module names.
  Keep `What changed` to under 10 words. Put the nuance in `Details`.
- **Testing plan**: Prefer commands over prose. A reviewer should be able to copy each command
  verbatim. Include setup steps if needed (e.g., "start the dev server first"). Reference specific
  test names or describe blocks.
- **Risks**: Be honest. "No consumer wiring yet" is more useful than "No risks". If this is a
  pure refactor with full test coverage, say that.

## Step 6: Create or update the PR

### Creating a new PR

```bash
gh pr create --title "<title>" --body "<body>"
```

If the user's branch name or conversation suggests this should be a draft, add `--draft`.

### Updating an existing PR

Use the GitHub REST API to update both title and body (this avoids `gh pr edit` issues with
Projects classic):

```bash
gh api repos/{owner}/{repo}/pulls/{number} -X PATCH \
  -f title='<new title>' \
  -f body='<new body>' \
  --silent
```

### After either path

Output the PR URL so the user can review it.
