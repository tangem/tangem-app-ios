//
//  FeedSearchHistory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct FeedSearchHistory: Hashable {
    let queries: [FeedRecentQuery]

    static let empty = FeedSearchHistory(queries: [])

    var isEmpty: Bool {
        queries.isEmpty
    }
}
