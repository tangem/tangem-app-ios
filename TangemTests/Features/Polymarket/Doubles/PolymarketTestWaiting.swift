//
//  PolymarketTestWaiting.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing

@MainActor
func settle(
    timeout: Duration = .seconds(3),
    until isSatisfied: () -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) async throws {
    let attempts = Int(timeout / .nanoseconds(Int64(PolymarketTestWaiting.interval)))

    for _ in 0 ..< attempts {
        if isSatisfied() { return }

        try await Task.sleep(nanoseconds: PolymarketTestWaiting.interval)
    }

    Issue.record("The condition never became true", sourceLocation: sourceLocation)
}

@MainActor
func drain() async throws {
    for _ in 0 ..< PolymarketTestWaiting.drainAttempts {
        try await Task.sleep(nanoseconds: PolymarketTestWaiting.interval)
    }
}

private enum PolymarketTestWaiting {
    static let drainAttempts = 10
    static let interval: UInt64 = 10_000_000
}
