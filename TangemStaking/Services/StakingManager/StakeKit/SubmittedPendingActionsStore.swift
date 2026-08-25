//
//  SubmittedPendingActionsStore.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Keeps actions the app has just submitted so they can back the in-progress UI
/// before StakeKit's actions list reflects them: the list lags the submit by seconds,
/// and fast integrations (e.g. TON pools) may never report the action as PROCESSING at all.
protocol SubmittedPendingActionsStore {
    /// Snapshots the store's last-seen balances as the baseline for detecting
    /// when the submitted action gets reflected in balances.
    func register(action: StakingAction)

    /// Returns server actions plus still-relevant submitted ones and records `currentBalances`
    /// as the new last-seen baseline. A submitted action is dropped once the server list
    /// contains its counterpart, the balances change against its baseline (the operation
    /// is reflected), or its lifetime elapses.
    func mergeWithServerActions(
        _ serverActions: [PendingAction],
        currentBalances: [StakingBalanceInfo]
    ) -> [PendingAction]
}

final class CommonSubmittedPendingActionsStore {
    private let lifetime: TimeInterval
    private let now: () -> Date
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(lifetime: TimeInterval, now: @escaping () -> Date = Date.init) {
        self.lifetime = lifetime
        self.now = now
    }

    private func mapToPendingActionType(from type: StakingAction.ActionType) -> StakingPendingActionInfo.ActionType {
        switch type {
        case .stake: .stake
        case .unstake: .unstake
        case .pending(.withdraw): .withdraw
        case .pending(.claimRewards): .claimRewards
        case .pending(.restakeRewards): .restakeRewards
        case .pending(.voteLocked): .voteLocked
        case .pending(.unlockLocked): .unlockLocked
        case .pending(.restake): .restake
        case .pending(.stake): .stake
        case .pending(.claimUnstaked): .claimUnstaked
        }
    }
}

// MARK: - SubmittedPendingActionsStore

extension CommonSubmittedPendingActionsStore: SubmittedPendingActionsStore {
    func register(action: StakingAction) {
        let pendingAction = PendingAction(
            id: UUID().uuidString,
            status: .processing,
            amount: action.amount,
            type: mapToPendingActionType(from: action.type),
            currentStepIndex: 0,
            transactions: [],
            targetAddress: action.targetType.target?.address
        )

        let submittedAt = now()

        state.withLock { state in
            state.entries.append(
                Entry(action: pendingAction, balancesSnapshot: state.lastSeenBalances, submittedAt: submittedAt)
            )
        }
    }

    func mergeWithServerActions(
        _ serverActions: [PendingAction],
        currentBalances: [StakingBalanceInfo]
    ) -> [PendingAction] {
        let currentDate = now()

        return state.withLock { state in
            state.lastSeenBalances = currentBalances
            state.entries.removeAll { entry in
                currentDate.timeIntervalSince(entry.submittedAt) > lifetime
                    || currentBalances != entry.balancesSnapshot
                    || serverActions.contains(where: entry.action.isCounterpart(of:))
            }

            return serverActions + state.entries.map(\.action)
        }
    }
}

private extension CommonSubmittedPendingActionsStore {
    struct Entry {
        let action: PendingAction
        let balancesSnapshot: [StakingBalanceInfo]
        let submittedAt: Date
    }

    struct State {
        var entries: [Entry] = []
        var lastSeenBalances: [StakingBalanceInfo] = []
    }
}

private extension PendingAction {
    func isCounterpart(of serverAction: PendingAction) -> Bool {
        type == serverAction.type
            && targetAddress == serverAction.targetAddress
            && amount == serverAction.amount
    }
}
