//
//  FeedSearchHistoryStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol FeedSearchHistoryStorage {
    func load() -> StoredFeedSearchHistory?
    func save(_ history: StoredFeedSearchHistory)
}
