---
name: bump-tools
description: Bump the .tools-version - create the Jira ticket, update .tools-version, and open a PR to a target branch (default develop)
argument: version - Target tools version (e.g., 16.1.87)
---

# Bump Tools Version

This skill automates updating the `.tools-version` file in the repository root to a new version. It creates the Jira ticket, updates the file, and opens a PR to a target branch the user confirms (defaulting to `develop`). Modeled on the `bump-ci-xcode` skill.

## What `.tools-version` is

A single line holding the version of the archive-analysis tooling CI uses during deploy. It is read by the deploy workflows (`.github/workflows/build-deploy-{alpha,beta,internal,release}.yml`, via `cat .tools-version`) and forwarded to `fastlane` as `analyze_archive_tools_version`. It has **no effect on the app binary or runtime behavior** — changing it only changes which tool version the deploy pipeline runs.

The file ends with a **trailing newline** — preserve it when editing (unlike `.xcode-version`, which has none).

## Prerequisites

- Jira MCP configured and authenticated
- GitHub MCP configured and authenticated

## Steps

### 1. Parse Arguments and Read Current State

- Extract the target version from `$ARGUMENTS` (e.g., `16.1.87`).
- Read `.tools-version` to get the current version for the ticket description and commit message.
- Confirm with the user which branch the PR should target. Default to `develop` if they don't specify one.

### 2. Create the Jira Ticket

Follow the conventions in AGENTS.md (cloudId, field IDs, ADF caveats are documented there).

- **Summary:** `Bump tools version to <version>`
- **Description** (ADF): a single bullet — PR to `develop` updating `.tools-version` from `<current>` to `<version>`.
- **Story Points (`customfield_10025`):** `1`
- **QA Notes (`customfield_11232`):** the team's standard one-line "technical task, no testing needed" note (ADF). The change has zero runtime/binary impact.
- **Sprint (`customfield_10021`):** active sprint id (read it off any open ticket on board 12).
- Assign to the current user via a follow-up `editJiraIssue` call (the create-time shorthand is silently dropped) and verify.
- Transition the ticket to `In Progress`.

### 3. Create the Branch

Branch off the confirmed target branch (`develop` by default):

```bash
git fetch origin <target_branch>
git checkout -b IOS-NNNNN_bump_tools_<version_snake_case> origin/<target_branch>
git push -u origin IOS-NNNNN_bump_tools_<version_snake_case>
```

Push immediately so the branch tracks its own remote instead of `origin/<target_branch>`.

### 4. Update `.tools-version`

Replace the content with the new version, **keeping the trailing newline**:

```bash
printf '%s\n' '<version>' > .tools-version
```

### 5. Commit and Push

Single commit, GPG-signed (repo requirement):

- Subject: `IOS-NNNNN Bump tools version to <version>`
- Body: one sentence on the why.

Verify the signature with `git log --show-signature -1` before pushing.

### 6. Open the PR

Open a PR to the confirmed target branch (`develop` by default). The body MUST contain the Jira link on its own line so the Atlassian/GitHub integration links it back to the ticket:

```
[IOS-NNNNN](https://tangem.atlassian.net/browse/IOS-NNNNN)
```

**Do not assign reviewers manually.** `.tools-version` is owned by `@tangem-developments/ios-core` in `.github/CODEOWNERS`, so GitHub requests the review automatically.

### 7. Report Result

Output the Jira ticket key and URL, and the PR URL.
