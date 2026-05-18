# TangemPay Polling Service — Revert to Single-Poll-Per-Instance, Lift Multi-Order Concerns to Callers

**Status:** Proposed, not started. Should be a **separate ticket** from [REDACTED_INFO] (the multi-card refactor) — ship after [REDACTED_INFO] lands on develop.

**Author / driver:** Aleksei Muraveinik

**Branch context at time of writing:** `feature/[REDACTED_INFO]_tangempay_multiple_cards` rebased onto `origin/develop`. This refactor is orthogonal to the multi-card content.

---

## Motivation

`TangemPayOrderStatusPollingService` was originally designed (commit `177c736bcb`, "[REDACTED_INFO] TangemPay refactoring", Jan 2026) as **single-poll-per-instance**:

```swift
private var orderStatusPollingTask: Task<Void, Never>?

public func startOrderStatusPolling(orderId:, interval:, onCompleted:, onCanceled:, onFailed:) {
    orderStatusPollingTask?.cancel()
    orderStatusPollingTask = runTask { … }
}

public func cancel() { orderStatusPollingTask?.cancel() }
```

The intent: one service instance manages one poll at a time; concurrency across distinct polls is handled by giving each owner its own instance. The codebase already follows this ownership pattern:

- **`TangemPayCard`** owns its own service (created in `init`) — used for freeze / unfreeze / reissue on that card. By **FR-MOB-CONFLICT-001** these three are mutually exclusive on the same card → at most one poll per card.
- **`TangemPayBuilder`** has a single lazy service shared with **`TangemPayManager`** (first-card-issue, pre-account) and **`TangemPayAccount`** (additional-card-issue, post-account). These two never poll concurrently: the manager owns polling while `state == .issuingCard` (or earlier); it only hands off to `TangemPayAccount` once first-card issue has completed.

During [REDACTED_INFO] the service was grown into a **multi-poll registry** (`[String: ActiveTask]` dict + `NSLock` + per-entry `UUID` identity) to support what was thought to be "multiple concurrent issue orders." But:

- The spec (**FR-MOB-CONFLICT-001**, "Issue blocks Issue") forbids more than one issue in flight at a time.
- The conflict matrix for per-card lifecycle ops likewise forbids more than one poll per card.
- The first-card vs. additional-card paths don't temporally overlap.

So the dict/lock/UUID is paying for capability that's **never exercised**. At every call site the dict has size ≤ 1.

The correction is **not** to introduce a new type — it's to **revert the service to its original single-poll shape**, and lift the trivial "what to do about multiple orders" concerns (which only exist because the service grew machinery for it) back up to the callers, where they collapse naturally once the service is honest about its single-poll contract.

### What "lift multi-order management above" means concretely

The handful of places where callers leaned on the service's multi-order surface:

| Today | After revert |
|---|---|
| `orderStatusPollingService.cancel(orderId: staleOrder.id)` (in `resumeAdditionalCardIssuePolling`) — cancels the specific order's task | `orderStatusPollingService.cancel()` — cancels the only poll, which by spec is the only stale order anyway |
| `orderStatusPollingService.cancelAll()` (in `deinit` / state transitions) | `orderStatusPollingService.cancel()` — there's only one task to kill |
| Service holds `[String: ActiveTask]` keyed by orderId to handle `start(orderId: A); start(orderId: A)` deduplication | Caller's gate already prevents the duplicate `start` — the service no-ops the second call internally, but in practice it's never reached |
| Service uses UUID identity in `removeTask(orderId:, taskId:)` to protect against cancel-then-restart races | Service cancels previous task in `start(...)` before assigning the new one — same protection, no UUID needed |

The "multi-order management above" the service is largely **already** at the caller (`TangemPayAccount.activeIssueOrdersSubject`, the `TangemPayOperationGate` for cross-op conflicts). What's being lifted is the small remainder hiding inside the service.

### Side-effect: the operation gate becomes a candidate for deletion

This is **not the primary goal** of this refactor and should be evaluated separately after the revert lands. But worth noting because it informs the design:

- `TangemPayOperationGate.acquire(.issueCard)` semantically equals "is the account-level polling service currently polling?"
- `TangemPayOperationGate.acquire(.freeze(cardId: c))` / `.unfreeze(...)` / `.reissue(...)` semantically equals "is card `c`'s polling service currently polling?"
- `.rename(cardId:)` and `.setLimit(cardId:)` are non-polling, idempotent one-shots. Their gate protection is purely "prevent double-tap"; whether that's needed at all is a UX question for QA.

So a follow-on phase *could* delete `TangemPayOperationGate` and replace it with `service.isPolling` checks. **Don't bundle that with the revert** — keep changes small and reviewable. See "Phase 2 (deferred): consider gate collapse" below.

---

## Background — what exists today

### Files in scope

| Path | Role |
|---|---|
| `Modules/TangemPay/Order/TangemPayOrderStatusPollingService.swift` | The polling service. Currently multi-poll (dict + lock + UUID). Target of the revert. |
| `Modules/TangemPay/TangemPayOperationGate.swift` | The cross-operation conflict gate. **Untouched by Phase 1.** |
| `Tangem/Features/Visa/TangemPay/TangemPayBuilder.swift` | Instantiates the builder-level shared service. |
| `Tangem/Features/Visa/TangemPay/TangemPayAccount.swift` | Uses the shared service for additional-card-issue polling. Has `cancel(orderId:)` and `cancelAll()` call sites. |
| `Tangem/Features/Visa/TangemPay/TangemPayCard.swift` | Per-card service (created in init). Uses `startOrderStatusPolling` for freeze/unfreeze/reissue. No `cancelAll` calls (deinit only). |
| `Tangem/Features/Visa/TangemPay/TangemPayManager.swift` | First-card-issue polling. Has several `cancelAll()` call sites tied to state-machine transitions. |

### Spec invariants this must preserve

From `https://www.notion.so/tangem/Multiple-Cards-3445d34eb6788081861de610567dfdd2`:

- **FR-MOB-CONFLICT-001** — Conflict matrix:
  - Issue (any card) blocks issue (any card). Doesn't block withdraw, freeze/unfreeze of other cards, rename.
  - Freeze card A blocks unfreeze/freeze card A. Doesn't block operations on other cards or withdraw.
  - Unfreeze symmetric.
  - Withdraw blocks another withdraw. Doesn't block freeze/unfreeze/rename.
  - Reissue card A blocks freeze/unfreeze/reissue card A. Doesn't block operations on other cards.
  - Blocked action → "Something went wrong, try later" alert.
- **FR-MOB-ORDER-001** — `findOrders` is the source of truth; local `orderId` is a hint cache only.
- **FR-MOB-ORDER-002** — Pick the most recent active order by `updatedAt`.
- **FR-MOB-ORDER-004** — Local order cache must be invalidated on terminal statuses (COMPLETED, CANCELED).
- **FR-MOB-REFRESH-001** — Polling pauses in background, refreshes on foreground.

### Current shape of the service (multi-poll — the target of the revert)

```swift
public final class TangemPayOrderStatusPollingService {
    private struct ActiveTask {
        let id: UUID
        let task: Task<Void, Never>
    }
    private var orderStatusPollingTasks: [String: ActiveTask] = [:]
    private let lock = NSLock()

    public func startOrderStatusPolling(orderId:, interval:, onCompleted:, onCanceled:, onFailed:, onProgress:?) {
        lock.lock()
        if orderStatusPollingTasks[orderId] != nil { lock.unlock(); return }   // dedup
        let taskId = UUID()
        … starts task, on terminal: removeTask(orderId:, taskId:) ; then fires callback …
        orderStatusPollingTasks[orderId] = ActiveTask(id: taskId, task: task)
        lock.unlock()
    }

    public func cancel(orderId: String) { … cancels just that entry … }
    public func cancelAll() { … cancels all entries … }
    private func removeTask(orderId: String, taskId: UUID) { … identity-guarded cleanup … }
}
```

### Original shape of the service (target of the revert — from commit `177c736bcb`)

```swift
public final class TangemPayOrderStatusPollingService {
    private let customerService: CustomerInfoManagementService
    private var orderStatusPollingTask: Task<Void, Never>?

    public init(customerService: CustomerInfoManagementService) {
        self.customerService = customerService
    }

    public func startOrderStatusPolling(
        orderId: String,
        interval: TimeInterval,
        onCompleted: @escaping () -> Void,
        onCanceled: @escaping () -> Void,
        onFailed: @escaping (Error) -> Void
    ) {
        orderStatusPollingTask?.cancel()
        let polling = PollingSequence(interval: interval, request: { … getOrder(orderId:) … })
        orderStatusPollingTask = runTask {
            for await result in polling { … }
        }
    }

    public func cancel() { orderStatusPollingTask?.cancel() }

    deinit { orderStatusPollingTask?.cancel() }
}
```

### Diff between the two shapes (what to revert)

- Remove `ActiveTask` struct, `orderStatusPollingTasks` dict, `NSLock`, `cancelAll()`, `removeTask(orderId:taskId:)`, identity-protection logic in cleanup.
- Restore single `orderStatusPollingTask: Task<Void, Never>?`.
- Restore the original `cancel()` (no `orderId:` argument).
- Keep one feature added during [REDACTED_INFO]: **`onProgress` callback** for the issue-order polling. It's used by `TangemPayAccount.startAdditionalCardIssueTracking` to update the active order via `updateActiveIssueOrder(order)`. Add it as an optional parameter to the reverted `startOrderStatusPolling`.
- Keep the `PollOutcome`/`runPolling` extraction if convenient — that's a stylistic improvement over inline `for await` and doesn't impede the revert. Or roll it back too; reviewer's call. (My recommendation: roll back to inline `for await` — matches the original perfectly and is shorter overall.)
- Keep `TangemPayOrderStatusPollingError.terminalStatus(_:)` — it's used by callers' `onFailed`. The original didn't have it (it only handled `case .failure` from `PollingSequence`); during [REDACTED_INFO] the error path was extended to cover `case .failed, .undefined` from the BFF response. That's an actual improvement — keep it.

---

## Detailed Plan — Phase 1 (the revert)

### Step 1: Revert the service

Replace the entire body of `Modules/TangemPay/Order/TangemPayOrderStatusPollingService.swift` with the single-poll shape, preserving `onProgress` and `TangemPayOrderStatusPollingError`. Target shape:

```swift
public final class TangemPayOrderStatusPollingService {
    private let customerService: CustomerInfoManagementService
    private var orderStatusPollingTask: Task<Void, Never>?

    public init(customerService: CustomerInfoManagementService) {
        self.customerService = customerService
    }

    public func startOrderStatusPolling(
        orderId: String,
        interval: TimeInterval,
        onCompleted: @escaping () -> Void,
        onCanceled: @escaping () -> Void,
        onFailed: @escaping (Error) -> Void,
        onProgress: ((TangemPayOrderResponse) -> Void)? = nil
    ) {
        orderStatusPollingTask?.cancel()

        let polling = PollingSequence(
            interval: interval,
            request: { [customerService] in
                try await customerService.getOrder(orderId: orderId)
            }
        )

        orderStatusPollingTask = runTask {
            for await result in polling {
                switch result {
                case .success(let order):
                    switch order.status {
                    case .new, .processing:
                        onProgress?(order)
                        continue
                    case .completed:
                        onCompleted()
                        return
                    case .canceled:
                        onCanceled()
                        return
                    case .failed, .undefined:
                        onFailed(TangemPayOrderStatusPollingError.terminalStatus(order.status))
                        return
                    }
                case .failure:
                    continue
                }
            }
            onCanceled()   // sequence ended without terminal — treat as canceled
        }
    }

    public func cancel() {
        orderStatusPollingTask?.cancel()
    }

    deinit {
        orderStatusPollingTask?.cancel()
    }
}

public enum TangemPayOrderStatusPollingError: Error {
    case terminalStatus(TangemPayOrderResponse.Status)
}
```

A few subtle things to get right while reverting:

- **`onCanceled` on natural end-of-sequence**: the multi-poll version returned `.canceled` from `runPolling` when the `for await` loop completed without a terminal — that path fires `onCanceled` in the caller. Preserve this: call `onCanceled()` after the `for await` loop ends. Without this, the cooperative-cancellation case (`Task.cancel()` from `deinit`) silently never fires any callback — same as today, but worth being explicit.

- **`cancel()` semantics**: the original `cancel()` only cancels the task. It does **not** fire `onCanceled`. The task's own `for await` loop will exit due to cooperative cancellation and (per the bullet above) fire `onCanceled`. Verify with a unit test before committing.

- **Cancel-previous-on-start race**: `orderStatusPollingTask?.cancel(); orderStatusPollingTask = runTask { … }` is the original pattern. If two concurrent callers both call `startOrderStatusPolling`, the property assignment isn't atomic — but in practice every caller is `@MainActor`-bound or on the main run loop (ViewModels, `TangemPayAccount`, `TangemPayCard` ops all originate from UI). Document this assumption in a one-line comment on the property. If we ever start calling `start` off-main, this needs reconsideration.

### Step 2: Update `TangemPayAccount` (`resumeAdditionalCardIssuePolling`, `deinit`)

- `Tangem/Features/Visa/TangemPay/TangemPayAccount.swift:250` — replace `orderStatusPollingService.cancel(orderId: staleOrder.id)` with `orderStatusPollingService.cancel()`. The semantic is preserved: by spec there's at most one issue order in flight, and the service holds at most one task; if the caller is about to remove the stale order from `activeIssueOrdersSubject`, the task associated with it is the only task the service has.
  - **Subtle**: the loop iterates `localOrdersBeforeFetch where !bffOrderIds.contains(...)`. By spec the snapshot has ≤ 1 stale order. Calling `cancel()` inside the loop is fine (idempotent — second cancel is a no-op on an already-canceled task). But it's a minor smell to call it inside a loop body; consider hoisting outside the loop with a guard: "if any stale order exists, `service.cancel()` once."
- `Tangem/Features/Visa/TangemPay/TangemPayAccount.swift:313` — replace `orderStatusPollingService.cancelAll()` in `deinit` with `orderStatusPollingService.cancel()`. (Also redundant because the service's own deinit cancels — but keep the explicit cancel for clarity; the service's deinit only fires after the account drops its strong ref, and the account's ref might not be the last reference if the builder still holds one. The shared lifecycle here is messy enough that explicit cancellation on the way down is safer.)

### Step 3: Update `TangemPayCard`

- No call-site changes needed: `TangemPayCard.swift` only calls `startOrderStatusPolling` (no `cancelAll`, no `cancel(orderId:)`). The service is per-card and deinit'd with the card.
- Verify by re-grepping: `grep -n "orderStatusPollingService\." Tangem/Features/Visa/TangemPay/TangemPayCard.swift`.

### Step 4: Update `TangemPayManager`

- `Tangem/Features/Visa/TangemPay/TangemPayManager.swift` lines 170 / 227 / 238 / 311 — replace `orderStatusPollingService.cancelAll()` with `orderStatusPollingService.cancel()`. These are state-machine transitions and `deinit`; in every case there's at most one in-flight task to cancel.

### Step 5: Verify cancellation behavior with the shared instance

`TangemPayBuilder` hands the **same** service instance to both `TangemPayManager` (first-card path) and `TangemPayAccount` (additional-card path).

Cases to check by tracing through `TangemPayManager.refreshState`:

| Transition | What `cancel()` should do |
|---|---|
| Manager transitions out of `.issuingCard` to `.tangemPayAccount(account)` | The first-card poll terminated naturally → service has no task to cancel. The account starts its own poll on the same service. ✓ |
| Manager transitions out of `.issuingCard` to `.failedToIssueCard` (cancel/failure) | First-card poll task ends naturally and fires `onFailed`/`onCanceled`. Service's task is nil. The manager's explicit `cancel()` in the transition is a no-op safety net. ✓ |
| Account is alive and has a poll in flight, app force-quits | Service's `deinit` cancels. ✓ |
| Account is alive and a (logically impossible) manager-side cancellation fires `cancelAll()` on the shared service | After the revert, this becomes `cancel()` and the active poll dies. This case shouldn't happen by spec, but it's worth checking that `TangemPayManager.refreshState` doesn't path through a `cancelAll()` call site when `state == .tangemPayAccount(account)`. Read all four `cancelAll()` sites (170, 227, 238, 311) before committing. |

If case 4 can happen, that's a pre-existing bug — flag it but don't fix it in this revert.

### Step 6: Tests

- Unit-test the reverted service:
  - Start poll → progress → completed → `onCompleted` fires once. Task slot is nil after.
  - Start poll → progress → canceled → `onCanceled` fires once.
  - Start poll → BFF error status (`.failed`/`.undefined`) → `onFailed(.terminalStatus(...))` fires once.
  - Start poll → caller calls `cancel()` → `onCanceled` eventually fires (via cooperative cancellation through `PollingSequence`). Verify timing — depends on `PollingSequence`'s cancellation propagation.
  - Start poll A → start poll B (same instance) → first poll's task is canceled; B's task is the live one.
  - Service `deinit` → task cancelled.

- Integration scenarios (manual / UI test):
  - First card issue (fresh user): onboarding → KYC → poll → completes → card appears. (Manager path.)
  - Additional card issue: tap "+" → confirm → poll → success. (Account path.)
  - Cancel mid-issue: tap "+", quit before completion, relaunch → `resumeAdditionalCardIssuePolling` reconciles → if BFF says order is gone, local order is dropped and `cancel()` fires; service was never polling because account was just constructed. No spurious alerts.
  - Reissue mid-poll: card A reissue → background → foreground → poll resumes (per-card service was never canceled across foreground/background — verify this still works).
  - Per-card isolation: card A reissuing while card B freeze — both services run independently. Verify nothing in the diff couples them.

### Step 7: Self-review checklist

- All four `cancelAll()` references in `Tangem/` removed and replaced with `cancel()`.
- The `cancel(orderId:)` reference in `TangemPayAccount.resumeAdditionalCardIssuePolling` replaced with `cancel()` (or hoisted with a guard).
- Service no longer imports `Foundation` for `NSLock`. (Probably still needs `Foundation` for `TimeInterval`. Verify.)
- No public-API changes to `startOrderStatusPolling` beyond making `onProgress` optional with default nil (it was already optional in the multi-poll version).
- Service file is ~70 lines instead of ~135.
- `bundle exec fastlane test` and `bundle exec fastlane ui_test` green.

---

## Phase 2 (deferred): consider gate collapse

**Don't include this in the same PR.** Do it after Phase 1 lands and bakes for at least a release cycle.

After Phase 1, the polling service exposes a natural "is a poll in flight" via its private state. If we add `var isPolling: Bool { orderStatusPollingTask != nil }` (or even just expose the optional task by reference), `TangemPayOperationGate` becomes redundant for polling-based ops:

| Operation | Today | After Phase 2 |
|---|---|---|
| Issue card | `operationGate.acquire(.issueCard)` | `guard !account.orderStatusPollingService.isPolling` |
| Freeze / unfreeze / reissue card A | `operationGate.acquire(.freeze(cardId: a))` etc. | `guard !cardA.orderStatusPollingService.isPolling` |
| Rename card A | `operationGate.acquire(.rename(cardId: a))` | drop (BFF is idempotent) OR per-call `inFlight: Bool` |
| Set limit card A | `operationGate.acquire(.setLimit(cardId: a))` | drop OR per-call `inFlight: Bool` |

Per-card vs. per-account isolation falls out for free because each owner has its own service (or nil — for the manager-shared one, mutual exclusion with account is temporal, not logical).

**Open questions for Phase 2 (not Phase 1):**

- Is the gate observed externally — e.g. by ViewModels checking `isBusy(...)` to disable buttons? `grep -rn "operationGate\b\|isBusy" --include="*.swift" Tangem/` before doing anything destructive. If buttons read the gate, replace those reads with reads of the corresponding service's `isPolling` (or a published `isPollingPublisher` if needed).
- Should rename/setLimit retain double-tap protection? Confirm with QA. If yes, per-call `inFlight: Bool` on `TangemPayCard` is fine; the gate as a separate object isn't needed.
- Should the service expose `isPolling` as `@Published`, a `Publisher`, or just a plain `Bool` getter? Depends on whether any UI needs to react to it transitionally.

---

## Risk Register

| Risk | Mitigation |
|---|---|
| Reverted `cancel-previous-on-start` semantic accidentally cancels a still-needed poll | All known callers acquire the operation gate before calling `start`, so duplicate-start can't happen. Verify via grep that there's no `start(...)` without a preceding gate `acquire(...)`. |
| `onCanceled` fires twice (once from `task.cancel()` cooperative termination, once from natural sequence end) | The original code returned from the `for await` body on terminal — only one path fires the callback. Replicate exactly: `onCanceled()` at the end of `for await` only when the loop completes without terminal. Add a unit test. |
| Shared builder-level service has both manager and account holding strong refs; cancellation by one affects the other | By state-machine analysis they don't poll concurrently. Add a comment in the builder explaining the shared-lifecycle assumption. Phase 2 may want to split them. |
| Hidden caller relies on `cancelAll()` semantics (cancel multiple polls) | There is no such usage today — every `cancelAll()` site has at most one task at a time by spec. Grep before deletion. |
| Phase 2 (gate deletion) sneaks into Phase 1 PR | Discipline: Phase 1 is a pure revert plus the trivial caller-side `cancel(orderId:) → cancel()` and `cancelAll() → cancel()` renames. Anything else goes in a separate ticket. |
| Refactor regresses [REDACTED_INFO] fixes | `resumeAdditionalCardIssuePolling`'s snapshot-then-reconcile pattern, the `wasStillTracked` alert-suppression in `onCanceled`/`onFailed`, the `@Published isAnyCardReissuing` mirror, the cache-collision fix in `TangemPayTokenBalanceProvider` — all unrelated to the polling-service shape. Confirm they're not touched. |

---

## Test Plan

### Per-step unit tests (Phase 1)

- Service: progress → completed; progress → canceled (via task cancel); progress → BFF failed status → `onFailed`; natural sequence end → `onCanceled`; second `start` cancels first; `deinit` cancels.
- `TangemPayAccount.resumeAdditionalCardIssuePolling`: stale local order + empty BFF → local cleared, `cancel()` invoked, no `cardIssueFailureSubject` event (alert-suppression intact).
- `TangemPayAccount.issueAdditionalCard`: gate guard still rejects when service is polling; new order → poll starts.
- `TangemPayCard.freeze` / `unfreeze` / `reissue`: same-card mutual exclusion preserved (gate); per-card service handles single poll correctly.
- `TangemPayManager.refreshState` transitions: each state change cancels the service appropriately.

### Manual scenarios (full UI walk)

1. **First card issue** (fresh user): onboarding → KYC pass → poll spins → completes → card appears.
2. **Additional card issue** (one card already active): tap "+" → confirm → poll → success → second card appears.
3. **Background / foreground during issue**: tap "+", background app for >30s, foreground → poll resumes via `resumeAdditionalCardIssuePolling` and reconciles.
4. **Reissue**: trigger reissue, observe replacing banner; while polling, same-card freeze/reissue rejected; cross-card freeze succeeds.
5. **Issue blocked by issue**: tap "+", before completion try to tap "+" again → second tap rejected with "operation busy" alert.
6. **Stale-order reconciliation**: start issue, force-quit mid-poll, BFF completes order, relaunch → `findOrders` empty → local stale order removed, no spurious alert, can issue again.
7. **Concurrent reissue + cross-card freeze**: card A reissue starts → freeze card B → both proceed independently.

### Regression scenarios from [REDACTED_INFO]

- `1↔0` balance blink (cache collision in `TangemPayTokenBalanceProvider`) — not touched, should not regress.
- Stale "issuing" entry on return-to-screen — reconciliation loop preserved with `cancel()` instead of `cancel(orderId:)`.
- `shouldDisplayReplacingCardBanner` per-card via `card.isReissuing` — not touched.

---

## Resumption Context (for future-me after compaction)

### Where I am

- Repo: `/Users/alekseimuraveinik/work/tangem-app-ios/`
- Plan file: `plans/tangempay-polling-service-refactor.md` (this file)
- Likely branch: `feature/[REDACTED_INFO]_tangempay_multiple_cards` is the multi-card branch. **This revert should target a new branch off `develop` after [REDACTED_INFO] lands** (`feature/IOS-XXXXX_tangempay_polling_revert` or similar). Get a new IOS ticket created — Story Points likely 2 (small, mechanical revert + a handful of caller updates).

### Repo conventions (from `CLAUDE.md`)

- Every change carries a Jira ticket: branch `IOS-NNNNN_short_desc`, commit subject `IOS-NNNNN Short desc`, PR title same as commit subject. PR body must include `[IOS-NNNNN](https://tangem.atlassian.net/browse/IOS-NNNNN)`.
- QA Notes (`customfield_11232`) required on the ticket. ADF JSON for textarea custom fields.
- All commits GPG-signed. Never `--no-verify`.
- Self-review the diff before opening the PR.

### What this corrects from a previous draft

An earlier draft of this plan proposed *creating a new `TangemPayOrderStatusPoll` class to replace the service*. That was the wrong framing. The user (Aleksei Muraveinik) corrected it: the service was originally single-poll-per-instance by design; what needs to happen is **reverting** the multi-poll changes made during [REDACTED_INFO] and **lifting** the (largely trivial) multi-order management back to callers, not introducing a new type. This file is the corrected plan.

### Files I will need to read first

In rough order:

1. `Modules/TangemPay/Order/TangemPayOrderStatusPollingService.swift` — current shape.
2. Commit `177c736bcb` for the original shape: `git show 177c736bcb:Modules/TangemPay/Order/TangemPayOrderStatusPollingService.swift`.
3. `Tangem/Features/Visa/TangemPay/TangemPayAccount.swift` — sites at lines ~250 and ~313.
4. `Tangem/Features/Visa/TangemPay/TangemPayCard.swift` — verify no callsite changes needed.
5. `Tangem/Features/Visa/TangemPay/TangemPayManager.swift` — sites at lines 170, 227, 238, 311.
6. `Tangem/Features/Visa/TangemPay/TangemPayBuilder.swift` — for the shared-instance ownership picture.

### Spec source

`https://www.notion.so/tangem/Multiple-Cards-3445d34eb6788081861de610567dfdd2`

Most relevant FRs: FR-MOB-CONFLICT-001, FR-MOB-ORDER-001/002/004, FR-MOB-REFRESH-001.

### Definition of done (Phase 1)

- `Modules/TangemPay/Order/TangemPayOrderStatusPollingService.swift` is back to a single-`Task?` shape (~70 lines), preserving `onProgress` and `TangemPayOrderStatusPollingError`.
- All callers use the simplified surface: `cancel()` everywhere instead of `cancelAll()` / `cancel(orderId:)`.
- `TangemPayOperationGate` is **untouched** (Phase 2 concern).
- `bundle exec fastlane test` and `bundle exec fastlane ui_test` green.
- The [REDACTED_INFO] manual regression scenarios (stale-order reconciliation, balance blink, etc.) all pass.

### Definition of done (Phase 2, if pursued)

- `TangemPayOperationGate.swift` deleted.
- Gate semantics expressed as `service.isPolling` checks at each call site.
- Rename / setLimit protection resolved (drop or per-call flag, per QA).
