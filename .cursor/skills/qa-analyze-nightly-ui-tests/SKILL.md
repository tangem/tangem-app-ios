---
name: qa-analyze-nightly-ui-tests
description: Triages the nightly UI-test run on CI (the ui-tests-allure.yml workflow on develop). Pulls the failed tests from the run log, links each to its test code and recent app changes, classifies the root cause as app bug / test fix / mock issue / flaky, and reports findings with recommendations. Use when the user asks to "analyze nightly UI test failures", "triage nightly UI tests", "what failed last night", "разбери ночной прогон", "что упало ночью", or pastes a ui-tests-allure run URL with a triage intent. Read-only: it never runs tests, edits code, or files bugs — it hands those off to other skills.
argument: run - Optional run id or GitHub Actions run URL to analyze (defaults to the latest nightly run on develop)
---

# Analyze Nightly UI Tests

Triage the failed tests of the nightly UI-test run and produce a report classifying each failure as an app bug, a test fix, a mock issue, or flaky. Read-only end to end: read CI results and source, then report. Never run tests, edit code, or file bugs.

Repository is `tangem-developments/tangem-app-ios`, workflow `ui-tests-allure.yml`, default branch `develop`.

## Steps

### 1. Find the run

If `$ARGUMENTS` contains a run id or a GitHub Actions URL, use that run. Otherwise find the latest nightly run:

```bash
gh run list --workflow=ui-tests-allure.yml --branch develop --limit 15 \
  --json databaseId,event,status,conclusion,createdAt,displayTitle
```

Pick the most recent run with `event = "schedule"` (the nightly cron at 03:00 UTC). Handle edge cases:
- Latest nightly is still in progress → say so, offer to wait or analyze the previous nightly run.
- No scheduled run exists (only manual `workflow_dispatch`) → say so and offer the latest available run instead.
- `gh` is not authenticated → tell the user to run `! gh auth login` in the prompt.

### 2. Check the conclusion

```bash
gh run view <id>
```

If the run is green (no failures), report "no failures" and stop.

### 3. Verify the Allure report was created

The `Upload Allure Results to TestOps` step (`id: upload_results`, `if: always()`) runs `allurectl upload` and is the source of truth for the run's report. Read its log (already captured by `gh run view <id> --log`) and confirm the upload succeeded — a launch was created:
- Success: `Found Allure results, uploading to TestOps...` and `✅ Got launch ID: <n>` (a non-empty `launch_id`).
- Failure: `❌ No Allure results found to upload` or `⚠️ Could not get ALLURE_LAUNCH_ID`.

If the report was not created, the run's results are incomplete or unreliable: surface this prominently at the top of the report, treat the failure list as untrustworthy, and recommend re-running the workflow before triaging. Do not present a confident triage built on a missing report.

### 4. Pull failed tests from the step log

The `Run tests with Marathon` step (`id: tests`, `continue-on-error: true`) runs `marathon run` and prints the run summary with the failed tests and their errors. Read its log and extract the data — do not download artifacts:

```bash
gh run view <id> --log
```

Filter to the Marathon step section (between `Starting Marathon test run` and `=== Marathon test run completed ===`). From it pull, for each failure:
- the failed test FQN (`ClassName/testMethod` or `ClassName.testMethod`),
- the pass/fail counts,
- the error excerpt (assertion message, timeout, "no matches found for element", crash/termination, etc.),
- retry outcome if printed — a test that passed on a retry within the same run is a flaky candidate.

If the log is truncated or unavailable, fall back to `gh run view <id> --log-failed` and note the reduced depth in the report.

### 5. Link each failure to the code

Map the test to its source and check what changed recently:
- Grep the class/method in `TangemUITests/Tests/` and read the test.
- Read the page objects it uses in `TangemUITests/Screens/` and the accessibility identifiers in `Modules/TangemAccessibilityIdentifiers/`.
- Use `git log`/`git blame` over the last few days on the relevant production code and identifiers. Whether app behavior or an identifier changed recently is the key signal for "app bug vs test drift".

### 6. Classify each failure

Assign a category, a confidence level, and the evidence behind it, using the error text plus what the code and git history show:

| Category | Typical signals | Recommended owner |
|---|---|---|
| **App bug** | Assertion on a wrong value while the test matches the spec; wrong screen; app crash/termination; app behavior regressed in a recent commit | Dev — file a bug |
| **Test fix needed** | Element not found because an accessibility id was renamed/removed in production; changed flow; stale selector or expectation | QA automation — fix the test |
| **Mock / test-data issue** | Error indicates an unexpected/invalid API response or a mock scenario mismatch | QA automation — fix the mock |
| **Flaky / infra** | Element-wait timeout, passed on retry, simulator/Marathon infrastructure noise | Stabilize / quarantine |
| **Needs investigation** | Not enough signal to decide | Manual look |

### 7. Report

Output a markdown report to the chat:
- **Header:** run id, run date, GitHub run URL, totals (run / failed / flaky), and Allure-report status (created with launch id, or **not created — results unreliable**).
- **Summary table:** test • category • confidence • one-line reason.
- **Per-failure detail:** error excerpt, evidence (relevant production/identifier git diffs), recommended action.

Never silently truncate the failure list — if you cap the output, state how many were omitted.

### 8. Hand off (no automatic actions)

Do not file bugs or edit code. Offer the next step instead:
- App bug → suggest running `/qa-reporting-bugs` with the gathered context.
- Test or mock fix → suggest running `/qa-write-ui-test`.

The user decides whether and when to proceed.

## Constraints

- Never run UI tests (`fastlane`, `xcodebuild`, `marathon`) — only read CI results.
- Do not edit code or touch Jira; this skill only reads and reports.
- Do not download CI artifacts; the Marathon step log is the only data source.
