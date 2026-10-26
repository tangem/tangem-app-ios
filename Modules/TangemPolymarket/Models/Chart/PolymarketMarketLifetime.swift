//
//  PolymarketMarketLifetime.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketMarketLifetime: Hashable, Sendable {
    public let start: Date?
    public let status: Status

    public init(start: Date?, status: Status) {
        self.start = start
        self.status = status
    }

    public var isClosed: Bool {
        switch status {
        case .open:
            false
        case .closed:
            true
        }
    }

    public func age(at now: Date) -> TimeInterval {
        start.map { now.timeIntervalSince($0) } ?? PolymarketPriceInterval.assumedAgeWhenStartUnknown
    }

    func tradingEnd(at now: Date) -> Date {
        switch status {
        case .open:
            return now
        case .closed(let closedDate, let scheduledEndDate):
            guard let end = closedDate ?? scheduledEndDate else { return now }

            return Swift.min(end, now)
        }
    }
}

// MARK: - Status

public extension PolymarketMarketLifetime {
    enum Status: Hashable, Sendable {
        case open
        case closed(closedDate: Date?, scheduledEndDate: Date?)
    }
}
