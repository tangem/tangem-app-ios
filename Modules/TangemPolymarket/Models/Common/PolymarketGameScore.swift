//
//  PolymarketGameScore.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public enum PolymarketGameScore: Hashable, Sendable {
    case missing
    case esports(maps: Points, bestOf: Int?)
    case tennis(sets: [Points])
    case points(Points)
    case unrecognized

    public struct Points: Hashable, Sendable {
        public let first: Int
        public let second: Int
    }

    init(parsing raw: String?, period: String?) {
        guard let raw = raw?.trimmingCharacters(in: .whitespaces).nilIfEmpty else {
            self = .missing
            return
        }

        // [REDACTED_TODO_COMMENT]
        let isTennis = raw.contains(Separator.tennisSet) || raw.contains(Separator.tieBreakStart) || Self.isTennisPeriod(period)
        let score: PolymarketGameScore?

        if raw.contains(Separator.esportsSegment) {
            score = Self.esports(parsing: raw) ?? Self.result(parsing: raw)
        } else if isTennis {
            score = Self.tennis(parsing: raw)
        } else {
            score = Points(parsing: raw).map(PolymarketGameScore.points)
        }

        self = score ?? .unrecognized
    }
}

// MARK: - Parsing

private extension PolymarketGameScore {
    enum Separator {
        static let esportsSegment: Character = "|"
        static let tennisSet: Character = ","
        static let tieBreakStart: Character = "("
        static let sides: Character = "-"
        static let bestOfPrefix = "Bo"
        static let tennisPeriodPrefix: Character = "S"
    }

    static func isTennisPeriod(_ period: String?) -> Bool {
        guard let period, period.first == Separator.tennisPeriodPrefix else {
            return false
        }

        return Int(period.dropFirst()) != nil
    }

    static func esports(parsing raw: String) -> PolymarketGameScore? {
        let segments = raw.split(separator: Separator.esportsSegment, omittingEmptySubsequences: false)

        guard segments.count >= 2, let maps = Points(parsing: segments[1]) else {
            return nil
        }

        let bestOf = segments.dropFirst(2).first.flatMap { segment in
            segment.hasPrefix(Separator.bestOfPrefix) ? Int(segment.dropFirst(Separator.bestOfPrefix.count)) : nil
        }

        return .esports(maps: maps, bestOf: bestOf)
    }

    static func result(parsing raw: String) -> PolymarketGameScore? {
        raw.split(separator: Separator.esportsSegment, maxSplits: 1)
            .first
            .flatMap { Points(parsing: $0) }
            .map(PolymarketGameScore.points)
    }

    static func tennis(parsing raw: String) -> PolymarketGameScore? {
        var sets: [Points] = []

        for set in raw.split(separator: Separator.tennisSet) {
            guard let points = Points(parsing: set.prefix { $0 != Separator.tieBreakStart }) else {
                return nil
            }

            sets.append(points)
        }

        return sets.isEmpty ? nil : .tennis(sets: sets)
    }
}

private extension PolymarketGameScore.Points {
    init?(parsing raw: some StringProtocol) {
        let sides = raw
            .trimmingCharacters(in: .whitespaces)
            .split(separator: PolymarketGameScore.Separator.sides, omittingEmptySubsequences: false)

        guard sides.count == 2, let first = Int(sides[0]), let second = Int(sides[1]), first >= 0, second >= 0 else {
            return nil
        }

        self.init(first: first, second: second)
    }
}
