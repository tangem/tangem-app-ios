//
//  PolymarketFundsArrivalTrackerRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class PolymarketFundsArrivalTrackerRegistry {
    private let entries = OSAllocatedUnfairLock<[UserWalletId: Entry]>(uncheckedState: [:])

    func tracker(
        for userWalletId: UserWalletId,
        owner: AnyObject,
        balancePublisher: @autoclosure () -> AnyPublisher<Decimal?, Never>
    ) -> PolymarketFundsArrivalTracker {
        entries.withLockUnchecked { entries in
            entries = entries.filter { $0.value.tracker != nil }

            if let entry = entries[userWalletId], entry.owner === owner, let tracker = entry.tracker {
                return tracker
            }

            let tracker = PolymarketFundsArrivalTracker(balancePublisher: balancePublisher())
            entries[userWalletId] = Entry(tracker: tracker, owner: owner)
            return tracker
        }
    }
}

// MARK: - Entry

private extension PolymarketFundsArrivalTrackerRegistry {
    struct Entry {
        weak var tracker: PolymarketFundsArrivalTracker?
        weak var owner: AnyObject?
    }
}

// MARK: - Injection

private struct PolymarketFundsArrivalTrackerRegistryKey: InjectionKey {
    static var currentValue = PolymarketFundsArrivalTrackerRegistry()
}

extension InjectedValues {
    var polymarketFundsArrivalTrackerRegistry: PolymarketFundsArrivalTrackerRegistry {
        get { Self[PolymarketFundsArrivalTrackerRegistryKey.self] }
        set { Self[PolymarketFundsArrivalTrackerRegistryKey.self] = newValue }
    }
}
