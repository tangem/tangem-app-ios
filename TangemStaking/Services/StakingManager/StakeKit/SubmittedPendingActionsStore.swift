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
    func prepare(action: StakingAction)

    /// Marks the action as submitted. Its baseline for detecting when the action gets reflected
    /// in balances is the one snapshotted by `prepare(action:)`, or the store's last-seen balances
    /// if the action wasn't prepared.
    func register(action: StakingAction)

    /// Returns server actions plus still-relevant submitted ones and records `currentBalances`
    /// as the new last-seen baseline. An action is reflected once the balances of its target
    /// move against its baseline the way the action moves them, by at least half its amount (e.g. an unstake
    /// lowers the active amount). Each such change goes to the oldest affected action, and the remaining actions are
    /// re-baselined on it. Neither a reflected action nor its server counterpart is returned.
    /// A submitted action gives way to its server counterpart once the list contains it,
    /// and expires after its lifetime unless the server still reports it.
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

    private func makePendingAction(from action: StakingAction) -> PendingAction {
        PendingAction(
            id: UUID().uuidString,
            status: .processing,
            amount: action.amount,
            type: mapToPendingActionType(from: action.type),
            currentStepIndex: 0,
            transactions: [],
            targetAddress: action.targetType.target?.address
        )
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
    func prepare(action: StakingAction) {
        let pendingAction = makePendingAction(from: action)
        let preparedAt = now()

        state.withLock { state in
            state.entries.removeAll { !$0.isSubmitted }
            state.entries.append(
                Entry(action: pendingAction, balancesSnapshot: state.lastSeenBalances, updatedAt: preparedAt)
            )
        }
    }

    func register(action: StakingAction) {
        let pendingAction = makePendingAction(from: action)
        let submittedAt = now()

        state.withLock { state in
            if let index = state.entries.firstIndex(where: { !$0.isSubmitted && $0.action.isCounterpart(of: pendingAction) }) {
                state.entries[index].isSubmitted = true
                state.entries[index].updatedAt = submittedAt
            } else {
                state.entries.append(
                    Entry(
                        action: pendingAction,
                        balancesSnapshot: state.lastSeenBalances,
                        updatedAt: submittedAt,
                        isSubmitted: true
                    )
                )
            }
        }
    }

    func mergeWithServerActions(
        _ serverActions: [PendingAction],
        currentBalances: [StakingBalanceInfo]
    ) -> [PendingAction] {
        let currentDate = now()

        return state.withLock { state in
            state.lastSeenBalances = currentBalances

            let entriesWithServerCounterpart = state.handOverEntries(to: serverActions)
            state.markOldestAffectedEntryReflected(in: currentBalances)
            state.removeExpiredEntries(at: currentDate, lifetime: lifetime, keeping: entriesWithServerCounterpart)

            return state.visibleActions(from: serverActions)
        }
    }
}

private extension CommonSubmittedPendingActionsStore {
    struct Entry {
        let action: PendingAction
        var balancesSnapshot: [StakingBalanceInfo]
        var updatedAt: Date
        var isSubmitted = false
        var isHandedOver = false
        var isReflected = false

        func isAffected(by balances: [StakingBalanceInfo]) -> Bool {
            let delta = movedAmount(in: balances) - movedAmount(in: balancesSnapshot)
            let directedDelta = increasesMovedAmount ? delta : -delta

            return directedDelta > 0 && directedDelta >= action.amount / 2
        }

        private var increasesMovedAmount: Bool {
            switch action.type {
            case .stake, .vote, .voteLocked, .restake: true
            case .unstake, .withdraw, .claimUnstaked, .unlockLocked, .claimRewards, .restakeRewards: false
            }
        }

        private func movedAmount(in balances: [StakingBalanceInfo]) -> Decimal {
            balances
                .filter(isMovedByAction)
                .reduce(0) { $0 + $1.amount }
        }

        private func isMovedByAction(_ balance: StakingBalanceInfo) -> Bool {
            let isSameTarget = action.targetAddress == nil
                || balance.targetAddress == nil
                || balance.targetAddress == action.targetAddress

            guard isSameTarget else {
                return false
            }

            switch action.type {
            case .stake, .vote, .restake: return balance.balanceType != .rewards
            case .voteLocked, .unstake: return balance.balanceType == .active
            case .withdraw, .claimUnstaked: return balance.balanceType == .unstaked
            case .unlockLocked: return balance.balanceType == .locked
            case .claimRewards, .restakeRewards: return balance.balanceType == .rewards
            }
        }
    }

    struct State {
        var entries: [Entry] = []
        var lastSeenBalances: [StakingBalanceInfo] = []

        mutating func handOverEntries(to serverActions: [PendingAction]) -> Set<Int> {
            let handedOverFirst = entries.indices.filter { entries[$0].isHandedOver }
                + entries.indices.filter { !entries[$0].isHandedOver }
            var unmatchedServerActions = serverActions
            var entriesWithServerCounterpart = Set<Int>()

            for index in handedOverFirst {
                let action = entries[index].action

                guard let serverIndex = unmatchedServerActions.firstIndex(where: action.isCounterpart(of:)) else {
                    continue
                }

                unmatchedServerActions.remove(at: serverIndex)
                entries[index].isHandedOver = true
                entriesWithServerCounterpart.insert(index)
            }

            return entriesWithServerCounterpart
        }

        mutating func markOldestAffectedEntryReflected(in balances: [StakingBalanceInfo]) {
            guard let reflectedIndex = entries.firstIndex(where: { !$0.isReflected && $0.isAffected(by: balances) }) else {
                return
            }

            entries[reflectedIndex].isReflected = true

            for index in entries.indices where !entries[index].isReflected {
                entries[index].balancesSnapshot = balances
            }
        }

        mutating func removeExpiredEntries(at date: Date, lifetime: TimeInterval, keeping keptIndices: Set<Int>) {
            entries = entries.enumerated().compactMap { index, entry in
                let isExpired = entry.isSubmitted && date.timeIntervalSince(entry.updatedAt) > lifetime

                if isExpired, !keptIndices.contains(index) {
                    return nil
                }

                return entry
            }
        }

        func visibleActions(from serverActions: [PendingAction]) -> [PendingAction] {
            var reflectedActions = entries.filter(\.isReflected).map(\.action)
            let visibleServerActions = serverActions.filter { serverAction in
                guard let index = reflectedActions.firstIndex(where: { $0.isCounterpart(of: serverAction) }) else {
                    return true
                }

                reflectedActions.remove(at: index)
                return false
            }
            let submittedActions = entries
                .filter { $0.isSubmitted && !$0.isHandedOver && !$0.isReflected }
                .map(\.action)

            return visibleServerActions + submittedActions
        }
    }
}

private extension PendingAction {
    func isCounterpart(of serverAction: PendingAction) -> Bool {
        type == serverAction.type
            && targetAddress == serverAction.targetAddress
            && amount == serverAction.amount
    }
}
