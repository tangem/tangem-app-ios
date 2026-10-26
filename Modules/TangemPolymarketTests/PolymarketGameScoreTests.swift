//
//  PolymarketGameScoreTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket game score")
struct PolymarketGameScoreTests {
    @Test("Scores the sports socket and the feed sent on 21–22.10.2026 are read by their shape", arguments: [
        Row(raw: "000-000|1-0|Bo3", period: "2/3", score: .esports(maps: Points(first: 1, second: 0), bestOf: 3)),
        Row(raw: "22-20|0-0|Bo3", period: "1/3", score: .esports(maps: Points(first: 0, second: 0), bestOf: 3)),
        Row(raw: "6-7(4-7), 6-2, 0-2", period: "S3", score: .tennis(sets: [Points(first: 6, second: 7), Points(first: 6, second: 2), Points(first: 0, second: 2)])),
        Row(raw: "3-2", period: "S1", score: .tennis(sets: [Points(first: 3, second: 2)])),
        Row(raw: "98-101", period: "Q4", score: .points(Points(first: 98, second: 101))),
        Row(raw: "2-1", period: "2H", score: .points(Points(first: 2, second: 1))),
        Row(raw: "2-3|0-1|Bo5", period: "2/5", score: .esports(maps: Points(first: 0, second: 1), bestOf: 5)),
        Row(raw: "000-000|3-2|Bo5", period: "5/5", score: .esports(maps: Points(first: 3, second: 2), bestOf: 5)),
        Row(raw: "7-0", period: "Q1", score: .points(Points(first: 7, second: 0))),
        Row(raw: "1-0|KO/TKO", period: "FT", score: .points(Points(first: 1, second: 0))),
        Row(raw: "0-1|Decision - Unanimous", period: "FT", score: .points(Points(first: 0, second: 1))),
    ])
    func knownShapes(_ row: Row) {
        #expect(PolymarketGameScore(parsing: row.raw, period: row.period) == row.score)
    }

    @Test("No score yet is told apart from a score that cannot be read", arguments: [
        Row(raw: nil, period: nil, score: .missing),
        Row(raw: "", period: "Q1", score: .missing),
        Row(raw: "  ", period: nil, score: .missing),
        Row(raw: "1-", period: nil, score: .unrecognized),
        Row(raw: "-1-2", period: nil, score: .unrecognized),
        Row(raw: "a-b", period: nil, score: .unrecognized),
        Row(raw: "1-2-3", period: nil, score: .unrecognized),
    ])
    func missingOrUnreadable(_ row: Row) {
        #expect(PolymarketGameScore(parsing: row.raw, period: row.period) == row.score)
    }

    typealias Points = PolymarketGameScore.Points

    struct Row: CustomTestStringConvertible, Sendable {
        let raw: String?
        let period: String?
        let score: PolymarketGameScore

        var testDescription: String {
            "\(raw ?? "nil") in \(period ?? "no period")"
        }
    }
}
