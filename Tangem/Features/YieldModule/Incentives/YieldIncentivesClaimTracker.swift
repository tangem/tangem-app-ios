//
//  YieldIncentivesClaimTracker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// Keeps the single in-flight claim of a `(chainId, userAddress)` pair and resolves its outcome.
/// The reconciliation belongs here rather than to a screen, so leaving the screen neither abandons
/// a submitted claim nor lets a second one start.
actor YieldIncentivesClaimTracker {
    enum Event: Equatable {
        case submitted
        case confirmed
        case unresolved
    }

    /// How long one reconciliation round waits before the rewards are asked again. The wait handed to
    /// `claimSubmitted(awaitingClearance:)` is expected to give up within the same window.
    static let reconciliationWindow: TimeInterval = 120

    private enum Constants {
        static let reconciliationRounds = 3
        static let rewardsCacheWindow: TimeInterval = 30
    }

    private let incentivesManager: YieldIncentivesManager
    private nonisolated let eventSubject = PassthroughSubject<Event, Never>()

    private var reconciliationTask: Task<Void, Never>?

    private(set) var isClaimInFlight = false

    nonisolated var eventPublisher: AnyPublisher<Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(incentivesManager: YieldIncentivesManager) {
        self.incentivesManager = incentivesManager
    }

    func beginClaim() -> Bool {
        guard !isClaimInFlight else {
            return false
        }

        isClaimInFlight = true
        return true
    }

    /// For failures that are certain to have left the transaction unsent.
    func releaseClaim() {
        isClaimInFlight = false
    }

    /// `awaitingClearance` answers whether the submitted hash left the pending records, `false` when it gave up
    /// waiting for it.
    func claimSubmitted(awaitingClearance: @escaping () async -> Bool) {
        eventSubject.send(.submitted)

        startReconciliation { [weak self] in
            await self?.reconcile(awaitingClearance: awaitingClearance)
        }
    }

    /// The submission failed in a way that may still have reached a node, so the claim waits out the same
    /// window as a submitted one before the rewards decide its outcome.
    func claimSubmissionUnresolved() {
        eventSubject.send(.submitted)

        startReconciliation { [weak self] in
            await self?.reconcile {
                try? await Task.sleep(for: .seconds(Self.reconciliationWindow))
                return true
            }
        }
    }

    private func startReconciliation(_ operation: @escaping () async -> Void) {
        reconciliationTask?.cancel()
        reconciliationTask = Task {
            await operation()
        }
    }

    /// The rewards are the only authority on whether the claim landed: a pending record also disappears when the
    /// transaction is dropped or its status cannot be read. A hash that is still pending once the wait gives up
    /// has decided nothing either, so the guard survives into another round rather than letting a second claim in.
    private func reconcile(awaitingClearance: () async -> Bool) async {
        var event = Event.unresolved

        for _ in 0 ..< Constants.reconciliationRounds {
            let pendingCleared = await awaitingClearance()
            event = await outcome()

            if event == .confirmed {
                break
            }

            if pendingCleared {
                try? await Task.sleep(for: .seconds(Constants.rewardsCacheWindow))
                event = await outcome()
                break
            }
        }

        isClaimInFlight = false
        eventSubject.send(event)
    }

    private func outcome() async -> Event {
        do {
            // An absent summary means no module address or no rewards at all, which says as little about the
            // claim as a failed refresh does — and nothing is not a confirmation.
            guard let summary = try await incentivesManager.incentives(forceRefresh: true) else {
                return .unresolved
            }

            return summary.claimableRewards.isEmpty ? .confirmed : .unresolved
        } catch {
            return .unresolved
        }
    }
}

/// One tracker per `(chainId, userAddress)`, matching how the incentives themselves are shared.
final class YieldIncentivesClaimTrackerProvider {
    private struct Key: Hashable {
        let chainId: Int
        let userAddress: String
    }

    private let trackers = OSAllocatedUnfairLock(initialState: [Key: YieldIncentivesClaimTracker]())

    func tracker(chainId: Int, userAddress: String) -> YieldIncentivesClaimTracker {
        let key = Key(chainId: chainId, userAddress: userAddress.lowercased())

        return trackers.withLock { storage in
            if let tracker = storage[key] {
                return tracker
            }

            let tracker = YieldIncentivesClaimTracker(
                incentivesManager: InjectedValues[\.yieldIncentivesManagerProvider].manager(
                    chainId: chainId,
                    userAddress: userAddress
                )
            )

            storage[key] = tracker
            return tracker
        }
    }
}

private struct YieldIncentivesClaimTrackerProviderKey: InjectionKey {
    static var currentValue = YieldIncentivesClaimTrackerProvider()
}

extension InjectedValues {
    var yieldIncentivesClaimTrackerProvider: YieldIncentivesClaimTrackerProvider {
        get { Self[YieldIncentivesClaimTrackerProviderKey.self] }
        set { Self[YieldIncentivesClaimTrackerProviderKey.self] = newValue }
    }
}
