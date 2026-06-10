---
name: bump-ci-xcode
description: Bump the CI Xcode version - create the Jira ticket, update .xcode-version and .ios-sim-runtime, and open a PR to develop
argument: version - Target Xcode version (e.g., 26.5 or 26.4.1)
---

# Bump CI Xcode Version

This skill automates the recurring chore of moving CI to a new Xcode version (past examples: [REDACTED_INFO], [REDACTED_INFO], [REDACTED_INFO], [REDACTED_INFO]). It creates the Jira ticket, updates the two version files in the repository root, and opens a PR to `develop`.

## How CI consumes the version files

- `.xcode-version` — single line with the Xcode version. Read by `fastlane/Fastfile`, GitHub workflows (`.github/workflows/tests.yml` and others), and simulator scripts in `scripts/ci/ui-tests/`.
- `.ios-sim-runtime` — two lines: simulator device name (line 1) and iOS simulator runtime version (line 2).

Both files have **no trailing newline** — preserve that when editing.

## Prerequisites

- Jira MCP configured and authenticated
- GitHub MCP configured and authenticated
- A separate **IT Ops (Assist) ticket** asking the admins to install the new Xcode on the CI runners. This skill does not create it (it lives outside the IOS project) — remind the user about it. The PR must not be merged before the runners are updated, otherwise CI fails on toolchain selection.

## Steps

### 1. Parse Arguments and Read Current State

- Extract the target version from `$ARGUMENTS` (e.g., `26.5`).
- Read `.xcode-version` to get the current version for the ticket description and commit message.
- Read `.ios-sim-runtime` to get the current device name and runtime version.

### 2. Create the Jira Ticket

Follow the conventions in AGENTS.md (cloudId, field IDs, ADF caveats are documented there).

- **Summary:** `Bump CI Xcode version to <version>`
- **Description** (ADF, modeled on [REDACTED_INFO]), a bullet list with two items:
  - IT Ops (Assist) ticket asking the admins to update Xcode `<current>` to `<version>` on the CI runners
  - PR to develop updating `.xcode-version` and `.ios-sim-runtime` (if needed)
- **Story Points (`customfield_10025`):** `2`
- **QA Notes (`customfield_11232`):** the team's standard one-line "technical task, no testing needed" note (ADF)
- **Sprint (`customfield_10021`):** active sprint id (read it off any open ticket on board 12)
- Assign to the current user via a follow-up `editJiraIssue` call (the create-time shorthand is silently dropped) and verify.
- Transition the ticket to `In Progress`.

### 3. Create the Branch

```bash
git fetch origin develop
git checkout -b IOS-NNNNN_bump_ci_xcode_<version_snake_case> origin/develop
git push -u origin IOS-NNNNN_bump_ci_xcode_<version_snake_case>
```

Push immediately so the branch tracks its own remote instead of `origin/develop`.

### 4. Update the Version Files

- `.xcode-version`: replace the content with the new version, no trailing newline.
- `.ios-sim-runtime`: keep line 1 (device name) as-is, set line 2 to the new runtime version, no trailing newline.

```bash
printf '<version>' > .xcode-version
printf '<device name>\n<runtime version>' > .ios-sim-runtime
```

**Patch releases caveat:** patch versions of Xcode (e.g., 26.4 → 26.4.1) usually do not ship a new simulator runtime. In that case leave `.ios-sim-runtime` untouched ([REDACTED_INFO] had to roll this change back). If unsure, bump it and watch the CI run on the PR — roll back if simulator selection fails.

### 5. Commit and Push

Single commit, GPG-signed (repo requirement):

- Subject: `IOS-NNNNN Bump CI Xcode version to <version>`
- Body: one or two sentences on the why (CI runners are being updated, builds and UI tests must select the new toolchain/runtime).

Verify the signature with `git log --show-signature -1` before pushing.

### 6. Open the PR

Invoke the `create-pr` skill with `develop` as the target.

**The PR description MUST always mention the IT Ops ticket** — after the Jira link, state that an IT Ops (Assist) ticket needs to be created for the admins to install the new Xcode on the CI runners, and that the PR must be merged only after that is done. Include this note even if the ticket already exists (then link it instead).

### 7. Report Result

Output:
- The Jira ticket key and URL
- The PR URL
- A reminder that the IT Ops (Assist) ticket for the admins is a manual prerequisite and the PR waits for it
