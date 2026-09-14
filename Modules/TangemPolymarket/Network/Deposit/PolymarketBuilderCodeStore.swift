//
//  PolymarketBuilderCodeStore.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public final class PolymarketBuilderCodeStore {
    private let lifetime: TimeInterval
    private let now: () -> Date

    private let entries = OSAllocatedUnfairLock(initialState: [URL: Entry]())

    public init(
        lifetime: TimeInterval = Constants.lifetime,
        now: @escaping () -> Date = Date.init
    ) {
        self.lifetime = lifetime
        self.now = now
    }

    public func code(forHost host: URL) -> String? {
        guard let entry = entries.withLock({ $0[host] }) else { return nil }

        let age = now().timeIntervalSince(entry.fetchedAt)
        guard age >= 0, age < lifetime else { return nil }

        return entry.code
    }

    public func store(_ code: String, forHost host: URL) {
        let entry = Entry(code: code, fetchedAt: now())
        entries.withLock { $0[host] = entry }
    }
}

// MARK: - Nested types

private extension PolymarketBuilderCodeStore {
    struct Entry {
        let code: String
        let fetchedAt: Date
    }
}

// MARK: - Constants

public extension PolymarketBuilderCodeStore {
    enum Constants {
        public static let lifetime: TimeInterval = 24 * 60 * 60
    }
}
