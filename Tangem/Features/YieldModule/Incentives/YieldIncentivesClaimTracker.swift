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
        static let settlementPollInterval: TimeInterval = 15
        static let settlementTimeout: TimeInterval = 360
    }

    private nonisolated let eventSubject = PassthroughSubject<Event, Never>()

    private let pollInterval: TimeInterval
    private let timeout: TimeInterval

    init(
        pollInterval: TimeInterval = Constants.settlementPollInterval,
        timeout: TimeInterval = Constants.settlementTimeout
    ) {
        self.pollInterval = pollInterval
        self.timeout = timeout
    }

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

    func claimSubmitted(isReflectedByBackend: @escaping () async -> Bool) {
        settle(isReflectedByBackend: isReflectedByBackend)
    }

    func claimSubmissionUnresolved() {
        settle { false }
    }

    private func settle(isReflectedByBackend: @escaping () async -> Bool) {
        eventSubject.send(.submitted)

        let pollInterval = pollInterval
        let timeout = timeout

        settlementTask?.cancel()
        settlementTask = Task { [weak self] in
            let deadline = Date().addingTimeInterval(timeout)

            while !Task.isCancelled, Date() < deadline {
                if await isReflectedByBackend() {
                    break
                }

                try? await Task.sleep(for: .seconds(pollInterval))
            }

            guard !Task.isCancelled else {
                return
            }

            await self?.finishSettlement()
        }
    }

    private func finishSettlement() {
        settlementTask = nil
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
