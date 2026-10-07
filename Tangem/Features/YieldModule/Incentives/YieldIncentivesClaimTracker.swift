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

/// Keeps the single in-flight claim of a `(chainId, userAddress)` pair. The guard lives here rather than on a
/// screen, so leaving the screen neither abandons a submitted claim nor lets a second one start.
actor YieldIncentivesClaimTracker {
    enum Event: Equatable {
        case submitted
        case settled
    }

    enum Constants {
        /// How long one round waits for the submitted transaction to leave the pending records.
        static let settlementWindow: TimeInterval = 120
        static let settlementRounds = 3
    }

    private nonisolated let eventSubject = PassthroughSubject<Event, Never>()

    private var settlementTask: Task<Void, Never>?

    private(set) var isClaimInFlight = false

    nonisolated var eventPublisher: AnyPublisher<Event, Never> {
        eventSubject.eraseToAnyPublisher()
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

    /// `awaitingClearance` answers whether the submitted hash left the pending records.
    func claimSubmitted(awaitingClearance: @escaping () async -> Bool) {
        settle(awaitingClearance: awaitingClearance)
    }

    /// No hash to watch, so clearance is never reported and the guard is held for every round.
    func claimSubmissionUnresolved() {
        settle {
            try? await Task.sleep(for: .seconds(Constants.settlementWindow))
            return false
        }
    }

    private func settle(awaitingClearance: @escaping () async -> Bool) {
        eventSubject.send(.submitted)

        settlementTask?.cancel()
        settlementTask = Task { [weak self] in
            for _ in 0 ..< Constants.settlementRounds {
                if await awaitingClearance() {
                    break
                }
            }

            await self?.finishSettlement()
        }
    }

    private func finishSettlement() {
        isClaimInFlight = false
        eventSubject.send(.settled)
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

            let tracker = YieldIncentivesClaimTracker()

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
