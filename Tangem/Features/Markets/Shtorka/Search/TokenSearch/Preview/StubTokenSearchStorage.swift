//
//  StubTokenSearchStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// In-memory stub for ``TokenSearchStorage``.
/// Replace with a real implementation backed by AppSettings or PersistentStorage.
final class StubTokenSearchStorage: TokenSearchStorage {
    private let maxItems = 3

    // MARK: - Hints

    private(set) var hints: [String] = []

    func saveHint(_ query: String) {
        hints.removeAll { $0 == query }
        hints.insert(query, at: 0)
        if hints.count > maxItems {
            hints = Array(hints.prefix(maxItems))
        }
    }

    // MARK: - Recents

    private(set) var recents: [String] = []

    func saveRecent(assetId: String) {
        recents.removeAll { $0 == assetId }
        recents.insert(assetId, at: 0)
        if recents.count > maxItems {
            recents = Array(recents.prefix(maxItems))
        }
    }

    // MARK: - Clear All

    func clearAll() {
        hints.removeAll()
        recents.removeAll()
    }
}
