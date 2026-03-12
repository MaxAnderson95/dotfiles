---
description: Perform a PR Review
agent: build
#model: anthropic/claude-opus-4-5
---
Review PR $1 in this repo.

Please analyze the changes in this PR and focus on identifying critical issues related to:
- Potential bugs or issues
- Performance
- Security
- Correctness

You are in the same repo for this PR but not necessarily on the same branch as the PR. You may need to double check your current branch and checkout the PR using the `gh` CLI.

Also review the title and body of the PR, as well as the commit messages to give you additional context on the purpose of the change.

## Review Output Format:

**IMPORTANT:** Every comment you write — the main review body, inline comments on specific lines, and any reply to existing comments — MUST begin with `*Code Review by OpenCode* using {YOUR MODEL NAME HERE}` (rendered as italics). This is how your comments are distinguished from human comments since you share the same GitHub username.

Your review should create **inline comments** on specific lines of code, just like GitHub Copilot does. These appear as threaded discussions attached to specific lines in the "Files changed" tab. Inline comments should be reserved for specific suggestions or objections to the current code. If you want to state your agreeance with a particular piece of code without suggesting any changes, leave that for the general review comment instead.

### How to Submit a Review with Inline Comments

You MUST use the GitHub API to submit a review with inline comments. The `comments` array is what creates the inline threads on specific lines.

**Step 1: Get the repository and PR info**
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
COMMIT_SHA=$(gh pr view $1 --json headRefOid -q .headRefOid)

**Step 2: Create a JSON file with your review**
Create a file called in the local directory called tmp-review.json with this structure (REMEMBER NOT TO COMMIT IT AND TO CLEAN IT UP WHEN DONE):
{
  commit_id: COMMIT_SHA_HERE,
  event: COMMENT,
  body: ## Pull Request Review\n\n*Code Review by OpenCode*\n\nOverview summary here...\n\n**Confidence Score: X.X/10**,
  comments: [
    {
      path: path/to/file.go,
      line: 123,
      body: *Code Review by OpenCode*\n\nDescription of the issue.\n\n```suggestion\nsuggested replacement code\n```
    },
    {
      path: path/to/another_file.go,
      start_line: 45,
      line: 50,
      body: *Code Review by OpenCode*\n\nMulti-line comment for lines 45-50
    }
  ]
}

**Step 3: Submit the review**

gh api repos/$REPO/pulls/$1/reviews --input tmp-review.json

### Important Field Details for Inline Comments

Each comment in the comments array requires:
| Field | Required | Description |
|-------|----------|-------------|
| path | Yes | File path relative to repo root (e.g., internal/webhook/eviction_webhook.go) |
| line | Yes | The line number in the NEW version of the file (right side of diff) |
| body | Yes | Your comment text. **Must** begin with `*Code Review by OpenCode*\n\n` so it can be distinguished from human comments. Use  ``suggestion ` blocks for code fixes |
| start_line | No | For multi-line comments, the starting line number |
| side | No | Use "RIGHT" for commenting on new code (default) |

### Finding Correct Line Numbers

To get accurate line numbers for your comments:

1. Get the PR diff:
      gh pr diff $1
   
2. Line numbers in your comments should reference the NEW file's line numbers (the + lines in the diff, shown on the right side in GitHub's UI)

3. You can also view specific files at the PR's head commit:
      gh api repos/$REPO/contents/path/to/file?ref=BRANCH_NAME
   
### Code Suggestion Syntax

When you have a concrete fix, use GitHub's suggestion syntax in the comment body:

The current implementation has X issue because Y.
```suggestion
// Your suggested replacement code here
// This replaces the line(s) the comment is attached to
```

For multi-line suggestions, attach the comment to a range using start_line and line, then provide the full replacement in the suggestion block.

### Complete Example

#### Get repo and commit info

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
COMMIT_SHA=$(gh pr view 5 --json headRefOid -q .headRefOid)

#### Create review JSON

cat > tmp-review.json << 'EOF'
{
  "commit_id": "abc123...",
  "event": "COMMENT",
  "body": "## Pull Request Review\n\n*Code Review by OpenCode*\n\nReviewed 15 files for bugs, security, and performance issues.\n\n### Summary\n- Found 2 bugs\n- Found 1 performance issue\n\n**Confidence Score: 7.5/10**",
  "comments": [
    {
      "path": "internal/webhook/handler.go",
      "line": 142,
      "body": "*Code Review by OpenCode*\n\nThis nil check is missing, which could cause a panic if `config` is not initialized.\n\n```suggestion\nif config == nil {\n    return fmt.Errorf(\"config cannot be nil\")\n}\n```"
    },
    {
      "path": "internal/controller/reconciler.go",
      "start_line": 89,
      "line": 95,
      "body": "*Code Review by OpenCode*\n\nThis loop iterates over all items without pagination, which could cause memory issues in large clusters."
    }
  ]
}
EOF

#### Submit the review

`gh api repos/$REPO/pulls/5/reviews --input tmp-review.json`

## Review Process

1. Gather PR information:
      gh pr view $1 --json title,body,headRefOid,baseRefName,headRefName,files,commits
   gh pr diff $1
   
2. Check out the PR branch (if needed to read files):
      gh pr checkout $1
   
3. Analyze each changed file - read the actual source files to understand context beyond just the diff

4. Collect your findings - for each issue, note:
   - The file path
   - The specific line number(s)
   - A clear description of the issue
   - A suggested fix (if applicable)

5. Build your review JSON with:
   - A body containing your overall summary and confidence score
    - Your confidence score should reflect your overall opinion on whether merging the PR in that state will cause bugs, outage, or failed deployment. If you find a critical bug, your score should reflect that heavily.
   - A comments array with one entry per inline comment

6. Submit the review using gh api ... --input

7. Post the review URL so the developer can view it

## Existing Reviews

There may be review comments previously left by yourself, other AI agents such as CoPilot or Claude Code, and by human reviewers. Check existing reviews:

`gh api repos/$REPO/pulls/$1/reviews`
`gh api repos/$REPO/pulls/$1/comments`


Review their findings and decide on their merits. Incorporate any of their changes that you agree with in your own review. If you have any comments (both positive, or negative), you should leave an inline reply to their comment.

To reply to an existing review comment, use:
```
gh api repos/$REPO/pulls/$1/comments/{comment_id}/replies -f body="*Code Review by OpenCode*

Your reply here..."
```

Additionally perform a full check of the PR looking for anything that other reviewers might have missed. Look at comments left by real users which might explain why a previous suggestion was wrong. Take this into account on subsequent reviews.

Always leave a new review for each review request. Don't edit previous reviews. If you are not the first reviewer (either by your own review or someone else's) title the review "Follow-up Review" and style it as a follow-up to existing reviews. Be sure to check for additional commits made after reviews to see what was implemented.

## Final Output
When complete, output the URL to your review so the developer can quickly access it. The URL format is:
https://github.com/OWNER/REPO/pull/PR_NUMBER#pullrequestreview-REVIEW_ID
You can get the review ID from the API response when you submit the review.
If the user requesting the review has left any additional comments or context you should be aware of they will appear here: $ARGUMENTS