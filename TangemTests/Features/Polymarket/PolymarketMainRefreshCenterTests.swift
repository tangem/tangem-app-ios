//
//  PolymarketMainRefreshCenterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Polymarket main refresh center")
@MainActor
struct PolymarketMainRefreshCenterTests {
    @Test("A refresh reaches every registered block with its scope")
    func refreshReachesEveryBlock() async {
        let center = PolymarketMainRefreshCenter()
        let log = ScopeLog()

        center.register { log.append("first", $0) }
        center.register { log.append("second", $0) }

        await center.refresh(.accountFunds)

        #expect(log.entries.sorted() == ["first: accountFunds", "second: accountFunds"])
    }

    @Test("A refresh returns only after every block has finished")
    func refreshWaitsForEveryBlock() async {
        let center = PolymarketMainRefreshCenter()
        let log = ScopeLog()

        center.register { scope in
            try? await Task.sleep(nanoseconds: 50_000_000)
            log.append("slow", scope)
        }
        center.register { log.append("fast", $0) }

        await center.refresh(.full)

        #expect(log.entries.count == 2)
    }
}

// MARK: - Doubles

@MainActor
private final class ScopeLog {
    private(set) var entries: [String] = []

    func append(_ name: String, _ scope: PolymarketMainRefreshCenter.Scope) {
        entries.append("\(name): \(scope)")
    }
}
