---
description: Create a pull request from the current branch to a target branch with proper formatting, Jira link, and reviewers
argument: target_branch - The branch to merge into (e.g., releases/5.33, develop)
---

# Create Pull Request

Create a pull request from the current branch to the target branch: **$ARGUMENTS**

## Steps

### 1. Gather Information

Run these in parallel:

**Git commands:**
```bash
# Get current branch name
git rev-parse --abbrev-ref HEAD

# Get commits on this branch vs target
git log $ARGUMENTS..HEAD --oneline

# Get diff stats
git diff $ARGUMENTS..HEAD --stat
```

**Get iOS team members:**

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
- `base`: `$ARGUMENTS` (target branch)
- `body`: Use this format:
  ```
  [IOS-XXXXX](https://tangem.atlassian.net/browse/IOS-XXXXX)
  ```

### 5. Request Copilot Review

Use the `mcp__github__request_copilot_review` tool with:
- `owner`: `tangem-developments`
- `repo`: `tangem-app-ios`
- `pullNumber`: PR number from step 4

### 6. Add Human Reviewers

Use the `mcp__github__update_pull_request` tool to add reviewers:
- `owner`: `tangem-developments`
- `repo`: `tangem-app-ios`
- `pullNumber`: PR number from step 4
- `reviewers`: Select 2 random members from the team members fetched in step 1 (exclude the current user and service accounts like `gitservice_tangem`)

### 7. Report Result

Output the PR URL and confirm reviewers were added.
