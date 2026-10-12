//
//  PolymarketServerClock.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public final class PolymarketServerClock {
    private let deviceNow: () -> Date
    private let offset = OSAllocatedUnfairLock(initialState: TimeInterval?.none)

    public init(deviceNow: @escaping () -> Date = Date.init) {
        self.deviceNow = deviceNow
    }

    public var now: Date {
        guard let offset = offset.withLock({ $0 }) else {
            return deviceNow()
        }

        return deviceNow().addingTimeInterval(offset)
    }

    public func record(serverDate: Date) {
        offset.withLock { $0 = serverDate.timeIntervalSince(deviceNow()) }
    }
}
