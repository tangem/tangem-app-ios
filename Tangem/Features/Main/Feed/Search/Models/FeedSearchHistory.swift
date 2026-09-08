//
//  FeedSearchHistory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct FeedSearchHistory: Hashable {
    let tokens: [FeedRecentToken]
    let queries: [FeedRecentQuery]

    static let empty = FeedSearchHistory(tokens: [], queries: [])

    var isEmpty: Bool {
        tokens.isEmpty && queries.isEmpty
    }
}
