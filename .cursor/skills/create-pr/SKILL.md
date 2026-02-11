---
description: Create a pull request from the current branch to a target branch with proper formatting, Jira link, and reviewers
argument: target_branch - The branch to merge into (e.g., releases/5.33, develop)
argument: --draft - Optional flag to create a draft PR instead of a ready for review PR
---

# Create Pull Request

Create a pull request from the current branch to the target branch specified in `$ARGUMENTS`.

If `--draft` flag is present, create a draft PR (skips reviewer assignment).

## Steps

### 1. Gather Information

First, parse `$ARGUMENTS` to extract:
- `target_branch`: The branch name (excluding any flags)
- `is_draft`: `true` if `--draft` flag is present

Run these in parallel:

**Git commands:**
```bash
# Get current branch name
git rev-parse --abbrev-ref HEAD

# Get commits on this branch vs target (use target_branch, not raw $ARGUMENTS)
git log <target_branch>..HEAD --oneline

# Get diff stats
git diff <target_branch>..HEAD --stat
```

**Get iOS team members (skip if draft):**

If creating a draft PR, skip fetching team members since reviewers won't be assigned.

Otherwise, fetch team members:

(We use GH cli for this instead of GH MCP because currently GH MCP `get_team_members` tool just does not available for unknown reason)

```bash
gh api orgs/tangem-developments/teams/ios-team/members --jq '.[].login'
```

Filter the results to get potential reviewers (exclude service accounts like `gitservice_tangem`).

### 2. Extract Issue Number

From the branch name (e.g., `bugfix/[REDACTED_INFO]_description`), extract:
- Issue number: `IOS-XXXXX`
- PR title: `IOS-XXXXX: <description from commit message or branch>`

### 3. Push Branch to Remote

Ensure the current branch is pushed to the remote:

```bash
git push -u origin HEAD
```

### 4. Create PR via GitHub MCP

Use the `mcp__github__create_pull_request` tool with these parameters:
- `owner`: `tangem-developments`
- `repo`: `tangem-app-ios`
- `title`: `IOS-XXXXX: Short description`
- `head`: current branch name
- `base`: target branch from `$ARGUMENTS` (excluding `--draft` flag)
- `body`: Use this format:
  ```
  [IOS-XXXXX](https://tangem.atlassian.net/browse/IOS-XXXXX)
  ```
- `draft`: `true` if `--draft` flag is present in `$ARGUMENTS`, otherwise omit or set to `false`

### 5. Request Copilot Review (skip if draft)

**Skip this step if the PR was created as a draft.**

Use the `mcp__github__request_copilot_review` tool with:
- `owner`: `tangem-developments`
- `repo`: `tangem-app-ios`
- `pullNumber`: PR number from step 4

### 6. Add Human Reviewers (skip if draft)

**Skip this step if the PR was created as a draft.**

Use the `mcp__github__update_pull_request` tool to add reviewers:
- `owner`: `tangem-developments`
- `repo`: `tangem-app-ios`
- `pullNumber`: PR number from step 4
- `reviewers`: Select 2 random members from the team members fetched in step 1 (exclude the current user and service accounts like `gitservice_tangem`)

### 7. Report Result

Output the PR URL and confirm:
- Whether the PR was created as a draft or ready for review
- If not a draft: confirm reviewers were added
