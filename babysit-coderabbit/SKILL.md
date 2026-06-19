---
name: babysit-coderabbit
description: >
  Triage and handle CodeRabbit review comments on a PR — spawn subagents to inspect each comment,
  dismiss the ones that don't need fixing (with a reply explaining why), then fix the rest and push.
  Use this skill whenever the user wants to handle CodeRabbit feedback, babysit a PR's CodeRabbit review,
  triage CR comments, deal with CodeRabbit suggestions, or says things like "handle the coderabbit comments",
  "babysit coderabbit", "deal with CR feedback", "triage the review comments". Also trigger when the user
  mentions CodeRabbit comments need attention on a specific PR.
disable-model-invocation: true
---

# Babysit CodeRabbit

Triage CodeRabbit review comments on a PR by inspecting each one, deciding whether it needs a code fix or just a dismissal reply, then handling both groups in the right order.

## Arguments

`$ARGUMENTS` - Optional: PR number or URL. If not provided, detect from the current branch.

## Why the order matters

CodeRabbit re-reviews on every push. If you fix code first and then reply to dismissed threads, CodeRabbit sees the push, re-reviews, and may post new threads before you've finished replying — creating a mess. By replying to dismissed comments first (no push, no re-review triggered), you clear the noise before making code changes that trigger re-review.

## Workflow

### Step 1: Identify the PR and repo

```bash
# Get repo from git remote
gh repo view --json nameWithOwner --jq '.nameWithOwner'

# If PR number not provided, detect from current branch
gh pr view --json number,url --jq '{number: .number, url: .url}'
```

### Step 2: Fetch all unresolved CodeRabbit review threads

Use the GraphQL API to get unresolved threads authored by CodeRabbit, including the file path, line context, and the full comment body.

```bash
gh api graphql -f query='query {
  repository(owner:"{owner}", name:"{repo}") {
    pullRequest(number:{pr}) {
      reviewThreads(first:100) {
        nodes {
          id
          isResolved
          comments(first:10) {
            nodes {
              databaseId
              path
              body
              author { login }
              url
            }
          }
        }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[]
  | select(.isResolved == false)
  | select(.comments.nodes[0].author.login == "coderabbitai")
  | select(all(.comments.nodes[1:][]; .author.login == "coderabbitai") // (.comments.nodes | length) == 1)
  | {
      thread_id: .id,
      comment_id: .comments.nodes[0].databaseId,
      path: .comments.nodes[0].path,
      body: .comments.nodes[0].body,
      url: .comments.nodes[0].url,
      reply_count: (.comments.nodes | length)
    }'
```

The filter `select(all(.comments.nodes[1:][]; .author.login == "coderabbitai") // (.comments.nodes | length) == 1)` skips threads where a non-CodeRabbit user has already replied — this prevents duplicate dismissals when the skill runs repeatedly. Only threads with no replies, or where all replies are from CodeRabbit itself, are included.

If there are no unresolved CodeRabbit threads, report that and stop.

### Step 3: Inspect each comment with subagents

**You MUST spawn a subagent for every comment, even if there is only one.** Do not skip this step or inline the inspection yourself, regardless of how obvious the verdict seems. The subagent reads the actual file and makes the call — this keeps the main context clean and ensures consistent evaluation.

Spawn one subagent per CodeRabbit comment using the Agent tool. Run them in parallel (but cap at 5 concurrent to respect rate limits). Each subagent receives:

- The CodeRabbit comment body
- The file path
- The PR context

**Subagent prompt template:**

```
You are inspecting a CodeRabbit review comment to decide if it needs a code fix.

## CodeRabbit Comment
File: {path}
Comment: {body}

## Instructions

1. Read the file at `{path}` to understand the current code
2. Understand what CodeRabbit is suggesting
3. Decide: does this comment warrant a code change?

A comment NEEDS fixing when:
- It identifies a genuine bug, logic error, or security issue
- It points out a missing error handler that could cause a runtime failure
- It catches a real type safety problem
- It identifies a correctness issue (wrong variable, off-by-one, race condition)

A comment does NOT need fixing when:
- It's a style preference or subjective suggestion (e.g., "consider renaming X to Y")
- It suggests adding comments, documentation, or JSDoc that aren't required
- It recommends a refactor that doesn't fix a bug (e.g., "extract this into a helper")
- It's overly cautious about something that's already handled (e.g., null check on a value that's already validated upstream)
- It suggests adding validation for cases that can't actually occur
- It misunderstands the code's intent or surrounding context
- It conflicts with the project's established patterns or conventions

Output your verdict as a structured response:
- **Verdict**: DISMISS or FIX
- **Reason**: 1-2 sentence explanation of why
- **Fix description** (only if FIX): What code change is needed
```

### Step 4: Collect and sort results

After all subagents complete, collect their verdicts and split into two groups:

1. **DISMISS group** — comments to reply to with a reason
2. **FIX group** — comments that need code changes

### Step 5: Phase 1 — Reply to dismissed comments

Handle all DISMISS verdicts first. For each dismissed comment, reply in the same review thread explaining why the suggestion doesn't apply.

```bash
# Reply to the thread
gh api repos/{owner}/{repo}/pulls/{pr}/comments \
  -X POST \
  -f body="{reason}" \
  -F in_reply_to={comment_id}

# Resolve the thread so it won't reappear on subsequent runs
gh api graphql -f query='mutation {
  resolveReviewThread(input: {threadId: "{thread_id}"}) {
    thread { isResolved }
  }
}'
```

Always resolve the thread after replying. This prevents duplicate replies if the skill runs again, and works together with the reply-check filter in Step 2 as defense in depth.

The reply should be concise and technical — explain specifically why the suggestion doesn't apply to this code. Don't be dismissive or rude; acknowledge what CodeRabbit noticed but explain why no change is needed.

**Example reply tones:**

- "This null check isn't needed here — `userId` is validated by the auth middleware before this handler runs, so it's guaranteed to be non-null at this point."
- "The suggested refactor would improve readability in isolation, but this pattern is consistent with how all other workflow steps in this codebase handle the same concern. Changing just this one would create inconsistency."
- "CodeRabbit flagged a potential race condition, but the queue guarantees single-consumer processing per job ID, so concurrent access can't happen here."

### Step 6: Phase 2 — Fix comments that need addressing

Now handle all FIX verdicts. For each one:

1. Read the file and understand the context
2. Implement the fix
3. Verify the fix doesn't break anything (run relevant tests/lint if practical)

After fixing all issues, commit and push.

Do NOT reply to threads for comments you fixed — the code change speaks for itself, and CodeRabbit will re-review after the push.

### Step 7: Summary

Present a summary table:

```markdown
| # | File | Verdict | Action |
|---|------|---------|--------|
| 1 | src/foo.ts | DISMISS | Replied: already validated upstream |
| 2 | src/bar.ts | FIX | Fixed null check, committed in abc1234 |
| 3 | src/baz.ts | DISMISS | Replied: matches project pattern |
```

## Tips

- If a comment is borderline, lean toward DISMISS with a good explanation rather than making unnecessary code changes. Unnecessary changes create churn and can introduce bugs.
- CodeRabbit will re-review after the push from Phase 2. If it posts new comments, the user can run this skill again.
- For very large PRs (20+ threads), batch the subagent spawning into groups of 5 to avoid rate limit issues.
