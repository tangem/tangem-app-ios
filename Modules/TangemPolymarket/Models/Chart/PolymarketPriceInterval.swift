//
//  PolymarketPriceInterval.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketPriceInterval: String, CaseIterable, Hashable, Sendable {
    case hour = "1h"
    case sixHours = "6h"
    case day = "1d"
    case week = "1w"
    case month = "1m"
    case allTime = "max"

    public var duration: TimeInterval? {
        switch self {
        case .hour: Constants.hour
        case .sixHours: Constants.hour * 6
        case .day: Constants.day
        case .week: Constants.day * 7
        case .month: Constants.day * 30
        case .allTime: nil
        }
    }
}

// MARK: - History query

public extension PolymarketPriceInterval {
    func historyQuery(lifetime: PolymarketMarketLifetime, now: Date) -> PolymarketPriceHistoryQuery {
        guard let start = lifetime.start else {
            return .interval(self, fidelityMinutes: unknownAgeFidelityMinutes)
        }

        let age = lifetime.tradingEnd(at: now).timeIntervalSince(start)
        let resolved = grid(marketAge: age)

        guard self == .allTime else {
            return .interval(resolved.interval, fidelityMinutes: resolved.fidelityMinutes)
        }

        guard
            case .closed(let closedDate?, _) = lifetime.status,
            closedDate > start,
            closedDate.timeIntervalSince(start) <= Constants.boundedRangeLimit
        else {
            return .range(start: start, end: nil, fidelityMinutes: resolved.fidelityMinutes)
        }

        return .range(start: start, end: closedDate, fidelityMinutes: resolved.fidelityMinutes)
    }
}

// MARK: - Availability

public extension PolymarketPriceInterval {
    static let assumedAgeWhenStartUnknown: TimeInterval = Constants.day * 60

    static func available(marketAge: TimeInterval, isClosed: Bool) -> [Self] {
        guard !isClosed else { return [.allTime] }

        switch marketAge {
        case ..<Constants.day: return [.hour, .sixHours, .allTime]
        case ..<(Constants.day * 7): return [.hour, .sixHours, .day, .allTime]
        case ..<(Constants.day * 30): return [.hour, .sixHours, .day, .week, .allTime]
        default: return [.hour, .day, .week, .month, .allTime]
        }
    }
}

// MARK: - Grid

private extension PolymarketPriceInterval {
    struct Grid {
        let interval: PolymarketPriceInterval
        let fidelityMinutes: Int
    }

    var unknownAgeFidelityMinutes: Int {
        switch self {
        case .hour, .sixHours, .day, .week, .month:
            Constants.unknownAgeFidelityMinutes
        case .allTime:
            Constants.allTimeFidelityMinutes
        }
    }

    func grid(marketAge age: TimeInterval) -> Grid {
        if self == .hour || age < Constants.hour {
            return Grid(interval: .hour, fidelityMinutes: 1)
        }

        if self == .sixHours || age < Constants.hour * 6 {
            return Grid(interval: .sixHours, fidelityMinutes: 1)
        }

        if self == .day || age < Constants.day {
            return Grid(interval: .day, fidelityMinutes: 5)
        }

        if self == .week || age < Constants.day * 7 {
            return Grid(interval: .week, fidelityMinutes: age < Constants.day * 3.5 ? 15 : 30)
        }

        if self == .month || age < Constants.day * 30 {
            return Grid(interval: .month, fidelityMinutes: age < Constants.day * 15 ? 60 : 180)
        }

        return Grid(interval: .allTime, fidelityMinutes: Constants.allTimeFidelityMinutes)
    }
}

// MARK: - Constants

private extension PolymarketPriceInterval {
    enum Constants {
        static let hour: TimeInterval = 60 * 60
        static let day: TimeInterval = 24 * 60 * 60
        static let unknownAgeFidelityMinutes = 10
        static let allTimeFidelityMinutes = 720
        static let boundedRangeLimit: TimeInterval = day * 14
    }
}
