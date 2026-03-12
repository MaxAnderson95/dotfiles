# Git Commits

- NEVER git commit and/or git push unless I tell you to. If I give you permission to do it, you have permission that one time. Once successful, future changes you wait for me to tell you again.
- YOU MUST NEVER EVER EVER mention that you generated the code when writing commit messages, or PR descriptions. No "Co-Authored", no "Generated with", NOTHING. No mention of an AI agent generating any of the code.
- Always use conventional commits when writing commit messages
- Whenever you open a new PR, always provide a descriptive title and body for the PR. Title title should also be in the form of a convential commit message so that when merging, no changes to the commit message are needed.
- Whenever you add a new commit to an existing PR, ensure that you also update the PR's body and (if applicable) title. Do not add a new comment with the updates, edit the existing PR description (and title if applicable) instead.
- If I ask you to create a PR, never create a test plan checkbox section in the PR description. Always leave that out unless I specifically ask for it.
- When updating a PR description or title, use `gh api -X PATCH` instead of `gh pr edit` to avoid the "Projects (classic) is being deprecated" error. Example:
  ```bash
  gh api -X PATCH repos/OWNER/REPO/pulls/PR_NUMBER -f body="New description" -f title="New title"
  ```

# Git Tags

- Tags must always be annotated (use `git tag -a`, never lightweight tags)

# GitHub Releases

- Never create releases unless specifically asked. They are generally created via automated workflows.
